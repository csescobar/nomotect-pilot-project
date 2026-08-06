module Installation
  class Wizard
    Step = Data.define(:name, :path, :terminal)

    DEFAULT_STEPS = [
      Step.new(name: "appearance", path: "/installation/appearance", terminal: false),
      Step.new(name: "database", path: "/installation/database", terminal: false),
      Step.new(name: "provisioning", path: "/installation/provisioning", terminal: false),
      Step.new(name: "migrations", path: "/installation/migrations", terminal: false),
      Step.new(name: "platform_owner", path: "/installation/platform-owner", terminal: false),
      Step.new(name: "completed", path: "/installation/completed", terminal: true)
    ].freeze

    def initialize(steps: DEFAULT_STEPS)
      @steps = steps.index_by(&:name).freeze
    end

    def step(name)
      steps.fetch(name.to_s)
    rescue KeyError
      raise UnknownStep, "Unknown wizard step: #{name}"
    end

    def path_for(state)
      return step("appearance").path if state.to_s == "not_started" || state.to_s == "failed"

      step(state).path
    end

    def names
      steps.keys.freeze
    end

    private

    attr_reader :steps

    class UnknownStep < StandardError; end
  end
end
