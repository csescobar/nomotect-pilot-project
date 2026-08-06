require "digest"
require "fileutils"

module Installation
  class BrandingStore
    MAX_BYTES = 2.megabytes
    TYPES = {
      "image/png" => ".png",
      "image/jpeg" => ".jpg",
      "image/svg+xml" => ".svg",
      "image/x-icon" => ".ico"
    }.freeze

    def initialize(root: Rails.root.join("public/installation/branding"))
      @root = Pathname(root)
    end

    def store(upload, role:)
      return nil if upload.blank?

      content_type = upload.content_type.to_s
      extension = TYPES[content_type]
      raise ArgumentError, "Unsupported branding file type" unless extension

      bytes = upload.read
      raise ArgumentError, "Branding file is empty" if bytes.empty?
      raise ArgumentError, "Branding file is too large" if bytes.bytesize > MAX_BYTES
      raise ArgumentError, "Invalid SVG content" if content_type == "image/svg+xml" && unsafe_svg?(bytes)

      @root.mkpath
      filename = "#{role}-#{Digest::SHA256.hexdigest(bytes).first(16)}#{extension}"
      destination = @root.join(filename)
      temporary = @root.join(".#{filename}.tmp")
      temporary.binwrite(bytes)
      File.rename(temporary, destination)
      "/installation/branding/#{filename}"
    ensure
      upload.rewind if upload.respond_to?(:rewind)
      temporary&.delete if temporary&.exist?
    end

    private

    def unsafe_svg?(bytes)
      source = bytes.downcase
      source.include?("<script") || source.include?("javascript:") || source.include?("<!entity")
    end
  end
end
