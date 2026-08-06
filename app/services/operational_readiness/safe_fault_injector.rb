# frozen_string_literal: true

module OperationalReadiness
  class SafeFaultInjector
    def initialize(root:, environment:)
      @root = Pathname(root).realpath
      raise UnsafeFixture, "fault injection requires a production-like fixture" unless environment.to_s == "production-like"
    end

    def write(relative_path, content)
      path = bounded_path(relative_path)
      path.dirname.mkpath
      path.write(content)
      path
    end

    def remove(relative_path)
      path = bounded_path(relative_path)
      path.delete if path.file?
    end

    private

    attr_reader :root

    def bounded_path(relative_path)
      candidate = root.join(relative_path).cleanpath
      unless candidate.to_s.start_with?("#{root}#{File::SEPARATOR}")
        raise UnsafeFixture, "fault path escapes the certification fixture"
      end
      candidate
    end

    class UnsafeFixture < StandardError; end
  end
end
