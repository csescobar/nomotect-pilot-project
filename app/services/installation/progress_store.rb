require "json"

module Installation
  class ProgressStore
    MAX_EVENTS = 100

    def initialize(path: Rails.root.join("var/installation/progress.#{Rails.env}.json"))
      @path = Pathname(path)
    end

    attr_reader :path

    def publish(event:, status:, message:)
      events = read
      events << {
        "event" => event.to_s,
        "status" => status.to_s,
        "message" => message.to_s,
        "occurred_at" => Time.current.utc.iso8601
      }
      write(events.last(MAX_EVENTS))
      events.last
    end

    def read
      return [] unless path.exist?

      JSON.parse(path.read)
    rescue JSON::ParserError
      []
    end

    private

    def write(events)
      path.dirname.mkpath
      temporary = path.sub_ext("#{path.extname}.tmp")
      temporary.write(JSON.pretty_generate(events) + "\n")
      File.rename(temporary, path)
    ensure
      temporary&.delete if temporary&.exist?
    end
  end
end
