# frozen_string_literal: true

module RepositoryIntelligence
  class EventBus
    Event = Data.define(:name, :payload)

    def initialize
      @subscribers = Hash.new { |hash, key| hash[key] = [] }
    end

    def subscribe(name, callable = nil, &block)
      subscribers[name.to_sym] << (callable || block || raise(ArgumentError, "subscriber is required"))
      self
    end

    def publish(name, payload = {})
      event = Event.new(name: name.to_sym, payload: payload.freeze)
      subscribers[event.name].each { |subscriber| subscriber.call(event) }
      event
    end

    private

    attr_reader :subscribers
  end
end
