# frozen_string_literal: true

module Extensions
  class RegistrationContext
    THREAD_KEY = :nomotect_extension_registration
    Context = Data.define(:registry, :package)

    class << self
      def activate(registry:, package:)
        raise NestedContext, "extension registration context is already active" if current

        Thread.current.thread_variable_set(THREAD_KEY, Context.new(registry, package))
        begin
          yield
        ensure
          Thread.current.thread_variable_set(THREAD_KEY, nil)
        end
      end

      def register(id, &block)
        context = current
        raise RegistrationUnavailable, "extension registration is only available while loading" unless context

        context.registry.register(context.package, id, &block)
      end

      private

      def current
        Thread.current.thread_variable_get(THREAD_KEY)
      end
    end

    class RegistrationUnavailable < StandardError; end
    class NestedContext < StandardError; end
  end
end
