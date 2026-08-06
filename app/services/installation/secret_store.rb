require "fileutils"

module Installation
  module SecretStore
    class EnvFile
      def initialize(path: Rails.root.join("var/installation/runtime.#{Rails.env}.env"))
        @path = Pathname(path)
      end

      attr_reader :path

      def write!(values)
        path.dirname.mkpath
        temporary = path.sub_ext("#{path.extname}.tmp")
        temporary.write(values.sort.map { |key, value| "#{key}=#{escape(value)}" }.join("\n") + "\n")
        File.chmod(0o600, temporary)
        File.rename(temporary, path)
        File.chmod(0o600, path)
        path
      ensure
        temporary&.delete if temporary&.exist?
      end

      private

      def escape(value)
        %Q("#{value.to_s.gsub("\\", "\\\\").gsub('"', '\\"').gsub("\n", "\\n")}")
      end
    end
  end
end
