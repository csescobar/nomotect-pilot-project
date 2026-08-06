module Installation
  class StateMachine
    STATES = %w[not_started appearance database provisioning migrations platform_owner completed failed].freeze
    TRANSITIONS = {
      "not_started" => %w[appearance],
      "appearance" => %w[database failed],
      "database" => %w[provisioning failed],
      "provisioning" => %w[migrations failed],
      "migrations" => %w[platform_owner failed],
      "platform_owner" => %w[completed failed],
      "failed" => %w[appearance database provisioning migrations platform_owner],
      "completed" => []
    }.freeze

    def initialize(state)
      @state = state.to_s
      raise ArgumentError, "Unknown installation state: #{@state}" unless STATES.include?(@state)
    end

    attr_reader :state

    def transition_to(next_state)
      target = next_state.to_s
      raise ArgumentError, "Unknown installation state: #{target}" unless STATES.include?(target)
      raise InvalidTransition, "Cannot transition from #{state} to #{target}" unless TRANSITIONS.fetch(state).include?(target)

      self.class.new(target)
    end

    def completed?
      state == "completed"
    end

    class InvalidTransition < StandardError; end
  end
end
