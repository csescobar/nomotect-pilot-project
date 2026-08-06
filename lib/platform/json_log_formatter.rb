require "json"

module Platform
  class JsonLogFormatter < Logger::Formatter
    def call(severity, timestamp, program_name, message)
      payload = {
        timestamp: timestamp.utc.iso8601(6),
        severity: severity,
        program: program_name,
        message: normalize(message)
      }

      "#{JSON.generate(payload)}\n"
    end

    private

    def normalize(message)
      case message
      when String
        message
      when Hash
        message
      else
        message.inspect
      end
    end
  end
end
