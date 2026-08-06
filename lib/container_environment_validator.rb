# frozen_string_literal: true

require "uri"

class ContainerEnvironmentValidator
  REQUIRED = %w[DATABASE_URL SECRET_KEY_BASE].freeze

  def initialize(environment: ENV, output: $stderr)
    @environment = environment
    @output = output
  end

  def validate!
    errors = []
    errors.concat missing_variables
    errors.concat validate_database_url
    errors << "SECRET_KEY_BASE must contain at least 64 characters" if secret_key_base_present_but_short?

    return true if errors.empty?

    errors.each { |error| output.puts("container configuration error: #{error}") }
    false
  end

  private

  attr_reader :environment, :output

  def missing_variables
    REQUIRED.filter_map do |name|
      "#{name} is required" if environment[name].to_s.strip.empty?
    end
  end

  def validate_database_url
    value = environment["DATABASE_URL"].to_s
    return [] if value.empty?

    uri = URI.parse(value)
    return [ "DATABASE_URL must use postgres or postgresql" ] unless %w[postgres postgresql].include?(uri.scheme)
    return [ "DATABASE_URL must include a host" ] if uri.host.to_s.empty?
    return [ "DATABASE_URL must include a database name" ] if uri.path.to_s.delete_prefix("/").empty?

    []
  rescue URI::InvalidURIError
    [ "DATABASE_URL is invalid" ]
  end

  def secret_key_base_present_but_short?
    value = environment["SECRET_KEY_BASE"].to_s
    !value.empty? && value.length < 64
  end
end
