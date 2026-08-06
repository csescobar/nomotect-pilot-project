module LocalizationHelper
  def format_local_date(value, format: :long)
    return if value.blank?

    I18n.l(value.to_date, format: format)
  end

  def format_local_time(value, format: :long, time_zone: current_time_zone)
    return if value.blank?

    I18n.l(value.in_time_zone(time_zone), format: format)
  end

  def format_local_number(value, precision: 2)
    number_with_precision(value, precision: precision, strip_insignificant_zeros: true)
  end

  def format_local_percentage(value, precision: 1)
    number_to_percentage(value, precision: precision, strip_insignificant_zeros: true)
  end

  def format_local_currency(value, currency: current_currency)
    number_to_currency(value, unit: I18n.t("number.currency.units.#{currency.downcase}"))
  end

  def current_time_zone
    Current.user&.time_zone.presence || Localization::SupportedLocales.fetch(I18n.locale).time_zone
  end

  def current_currency
    Localization::SupportedLocales.fetch(I18n.locale).currency
  end
end
