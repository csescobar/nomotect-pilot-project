require "pg"

module Installation
  class DatabaseConnector
    def initialize(connection_factory: PG.method(:connect))
      @connection_factory = connection_factory
    end

    def test!(configuration)
      configuration.validate!
      with_connection(configuration) { |connection| connection.exec("SELECT 1") }
      true
    rescue PG::Error => error
      raise ConnectionError, sanitized_message(error)
    end

    def with_connection(configuration)
      configuration.validate!
      connection = connection_factory.call(configuration.connection_parameters)
      yield connection
    rescue PG::Error => error
      raise ConnectionError, sanitized_message(error)
    ensure
      connection&.close unless connection&.finished?
    end

    private

    attr_reader :connection_factory

    def sanitized_message(error)
      first_line = error.message.to_s.lines.first.to_s.strip
      first_line.presence || "PostgreSQL connection failed"
    end

    class ConnectionError < StandardError; end
  end
end
