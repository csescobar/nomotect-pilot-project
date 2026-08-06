# frozen_string_literal: true

module Extensions
  module Sdk
    module_function

    def register(id, &block)
      raise ArgumentError, "extension registration requires a block" unless block

      RegistrationContext.register(id, &block)
    end
  end

  def self.register(id, &block)
    Sdk.register(id, &block)
  end
end
