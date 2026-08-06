ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module TestMethodStubbing
  def stub(method_name, replacement)
    singleton = singleton_class
    direct = (singleton.instance_methods(false) + singleton.private_instance_methods(false) + singleton.protected_instance_methods(false)).include?(method_name)
    original = singleton.instance_method(method_name) if direct
    implementation = replacement.respond_to?(:call) ? replacement : ->(*) { replacement }
    singleton.define_method(method_name, implementation)
    yield
  ensure
    if direct
      singleton.define_method(method_name, original)
    else
      singleton.remove_method(method_name)
    end
  end
end

Module.prepend(TestMethodStubbing)

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end
