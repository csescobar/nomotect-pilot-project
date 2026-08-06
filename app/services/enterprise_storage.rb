require "fileutils"

class EnterpriseStorage
  class InvalidKey < StandardError; end

  def self.write(key, bytes)
    path = path_for(key)
    FileUtils.mkdir_p(path.dirname)
    temporary = path.sub_ext(".tmp-#{SecureRandom.hex(6)}")
    File.binwrite(temporary, bytes)
    File.rename(temporary, path)
    key
  ensure
    FileUtils.rm_f(temporary) if defined?(temporary) && temporary
  end

  def self.read(key)
    File.binread(path_for(key))
  end

  def self.delete(key)
    FileUtils.rm_f(path_for(key))
  end

  def self.path_for(key)
    raise InvalidKey unless key.match?(/\A\d+\/[0-9a-f-]{36}\z/)

    root = Rails.root.join("storage", "enterprise_files").expand_path
    path = root.join(key).expand_path
    raise InvalidKey unless path.to_s.start_with?("#{root}#{File::SEPARATOR}")

    path
  end
  private_class_method :path_for
end
