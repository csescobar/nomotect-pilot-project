# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "pathname"
require "rubygems/package"
require "stringio"
require "yaml"
require "zlib"
require "zip"

module ApplicationStarter
  class Builder
    def initialize(root:, output:, version:, source_commit:)
      @root = Pathname(root).expand_path
      @output = Pathname(output).expand_path
      @version = version
      @source_commit = source_commit
      @contract = YAML.safe_load(@root.join("config/distributions/application_starter.yml").read)
    end

    def build!
      validate!
      FileUtils.mkdir_p(@output)
      staging = @output.join("nomotect-starter-v#{@version}")
      FileUtils.rm_rf(staging)
      FileUtils.mkdir_p(staging)
      files.each { |relative| copy(relative, staging) }
      write_starter_files(staging)
      tar = @output.join("#{staging.basename}.tar.gz")
      zip = @output.join("#{staging.basename}.zip")
      write_tar(staging, tar)
      write_zip(staging, zip)
      checksums = [ tar, zip ].map { |path| "#{Digest::SHA256.file(path).hexdigest}  #{path.basename}" }
      @output.join("SHA256SUMS").write(checksums.join("\n") + "\n")
      { status: "ready", version: @version, files: files.size, tar: tar.to_s, zip: zip.to_s }
    ensure
      FileUtils.rm_rf(staging) if staging
    end

    private

    def validate!
      raise ArgumentError, "version is invalid" unless @version.match?(/\A\d+\.\d+\.\d+\z/)
      raise ArgumentError, "source commit is invalid" unless @source_commit.match?(/\A[a-f0-9]{40}\z/)
      raise ArgumentError, "output must not be inside the source tree" if @output.to_s.start_with?("#{@root}/")
    end

    def files
      @files ||= begin
        tracked = IO.popen([ "git", "-C", @root.to_s, "ls-files", "-z" ], &:read).split("\0")
        tracked.select { |path| included?(path) && !excluded?(path) }.sort
      end
    end

    def included?(path) = @contract.fetch("include").any? { |pattern| match?(pattern, path) }
    def excluded?(path) = @contract.fetch("exclude").any? { |pattern| match?(pattern, path) }
    def match?(pattern, path)
      return path.start_with?(pattern.delete_suffix("**")) if pattern.end_with?("**")

      File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
    end

    def copy(relative, staging)
      destination = staging.join(relative)
      FileUtils.mkdir_p(destination.dirname)
      FileUtils.cp(@root.join(relative), destination, preserve: true)
    end

    def write_starter_files(staging)
      staging.join("README.md").write("# Application Starter\n\nInitialize this workspace before development:\n\n```shell\nruby bin/nomotect-init.rb --product-name \"My Product\" --organization \"My Organization\" --repository my-product\n```\n")
      staging.join("CHANGELOG.md").write("# Changelog\n\nProduct history starts after Application Starter initialization.\n")
      manifest = {
        schema_version: 1,
        platform: { name: "NomoTect", version: @version, source_commit: @source_commit },
        distribution: "application-starter",
        files: files
      }
      staging.join("application-starter-manifest.json").write(JSON.pretty_generate(manifest) + "\n")
    end

  def write_tar(staging, destination)
      buffer = StringIO.new("".b)
      Gem::Package::TarWriter.new(buffer) do |tar|
          archive_files(staging).each do |path|
            relative = path.relative_path_from(staging.parent).to_s
            tar.add_file(relative, path.stat.mode) { |io| io.write(path.binread) }
          end
      end
      Zlib::GzipWriter.open(destination.to_s) { |gzip| gzip.write(buffer.string) }
    end

    def write_zip(staging, destination)
      Zip::File.open(destination.to_s, create: true) do |archive|
        archive_files(staging).each do |path|
          relative = path.relative_path_from(staging.parent).to_s
          archive.get_output_stream(relative) { |io| io.write(path.binread) }
        end
      end
    end

    def archive_files(staging) = staging.glob("**/*", File::FNM_DOTMATCH).select(&:file?).sort
  end
end
