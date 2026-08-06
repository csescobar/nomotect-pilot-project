require "digest"
require "fileutils"
require "tmpdir"

module Installation
  class DesignTokenInstaller
    MAX_BYTES = 64.kilobytes

    def initialize(source_root: Rails.root.join("config/design_tokens"))
      @source_root = Pathname(source_root)
    end

    def install!(yaml)
      content = yaml.to_s
      raise ArgumentError, "Design token YAML is required" if content.blank?
      raise ArgumentError, "Design token YAML is too large" if content.bytesize > MAX_BYTES

      Dir.mktmpdir("installation-design-tokens") do |directory|
        root = Pathname(directory)
        root.join("tokens.yml").write(content)
        FileUtils.cp(@source_root.join("tokens.schema.json"), root.join("tokens.schema.json"))

        css_output = root.join("design_tokens.css")
        ruby_output = root.join("generated.rb")
        compiler = DesignTokens::Compiler.new(root: root, css_output: css_output, ruby_output: ruby_output)
        compiler.write!

        promote!(root, css_output, ruby_output)
      end

      Digest::SHA256.hexdigest(content)
    end

    private

    def promote!(root, css_output, ruby_output)
      replacements = {
        @source_root.join("tokens.yml") => root.join("tokens.yml"),
        @source_root.join("base.json") => root.join("base.json"),
        @source_root.join("light.json") => root.join("light.json"),
        @source_root.join("dark.json") => root.join("dark.json"),
        Rails.root.join("app/assets/stylesheets/design_tokens.css") => css_output,
        Rails.root.join("lib/design_tokens/generated.rb") => ruby_output
      }

      replacements.each do |destination, source|
        destination.dirname.mkpath
        temporary = destination.sub_ext("#{destination.extname}.installation-tmp")
        FileUtils.cp(source, temporary)
        File.rename(temporary, destination)
      ensure
        temporary&.delete if temporary&.exist?
      end
    end
  end
end
