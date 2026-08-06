module Installation
  class ExecutionLock
    def initialize(path: Rails.root.join("var/installation/installation.lock"))
      @path = Pathname(path)
    end

    def synchronize
      path.dirname.mkpath
      path.open(File::RDWR | File::CREAT, 0o600) do |file|
        raise AlreadyLocked, "Another installation session is active" unless file.flock(File::LOCK_EX | File::LOCK_NB)

        yield
      ensure
        file&.flock(File::LOCK_UN)
      end
    end

    private

    attr_reader :path

    class AlreadyLocked < StandardError; end
  end
end
