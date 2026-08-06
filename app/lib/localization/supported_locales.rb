module Localization
  class SupportedLocales
    Entry = Data.define(:code, :label, :currency, :time_zone)

    ENTRIES = [
      Entry.new(code: "en", label: "English", currency: "USD", time_zone: "UTC"),
      Entry.new(code: "pt-BR", label: "Português (Brasil)", currency: "BRL", time_zone: "America/Sao_Paulo")
    ].freeze

    class << self
      def all = ENTRIES
      def codes = ENTRIES.map(&:code)
      def include?(value) = codes.include?(value.to_s)
      def fetch(value) = ENTRIES.find { |entry| entry.code == value.to_s } || default
      def default = fetch_without_fallback(I18n.default_locale.to_s) || ENTRIES.first
      def options = ENTRIES.map { |entry| [ entry.label, entry.code ] }

      private

      def fetch_without_fallback(value)
        ENTRIES.find { |entry| entry.code == value }
      end
    end
  end
end
