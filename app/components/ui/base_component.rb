module Ui
  class BaseComponent < ApplicationComponent
    private

    def validate_option!(name, value, allowed)
      return if allowed.include?(value)

      raise ArgumentError, "Unsupported #{name}: #{value.inspect}. Allowed: #{allowed.join(', ')}"
    end

    def class_names(*values)
      values.flatten.compact.flat_map { |value| value.to_s.split }.reject(&:empty?).uniq.join(" ")
    end

    def merged_html_options(defaults = {})
      supplied = @html_options.deep_dup
      supplied[:class] = class_names(defaults[:class], supplied[:class])
      supplied[:data] = (defaults[:data] || {}).merge(supplied[:data] || {})
      supplied[:aria] = (defaults[:aria] || {}).merge(supplied[:aria] || {})
      defaults.except(:class, :data, :aria).merge(supplied)
    end
  end
end
