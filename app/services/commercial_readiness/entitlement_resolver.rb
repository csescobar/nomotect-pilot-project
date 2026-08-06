# frozen_string_literal: true

module CommercialReadiness
  class EntitlementResolver
    Result = Data.define(:capability, :status, :source)

    def initialize(edition:, provider: nil)
      @edition = edition
      @provider = provider
    end

    def resolve(capability)
      capability = capability.to_s
      return Result.new(capability:, status: "available", source: "community") if edition.capabilities.include?(capability)
      return Result.new(capability:, status: "unavailable", source: "none") unless provider

      status = provider.call(capability)
      return Result.new(capability:, status: "available", source: "provider") if status == "available"

      Result.new(capability:, status: "unavailable", source: "provider")
    rescue StandardError
      Result.new(capability:, status: "unavailable", source: "provider")
    end

    private

    attr_reader :edition, :provider
  end
end
