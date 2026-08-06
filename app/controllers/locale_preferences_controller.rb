class LocalePreferencesController < ApplicationController
  allow_unauthenticated_access

  def update
    locale = params.require(:locale)

    unless Localization::SupportedLocales.include?(locale)
      redirect_back fallback_location: root_path, status: :see_other, alert: I18n.t("localization.unsupported")
      return
    end

    session[:locale] = locale
    resume_session
    Current.user&.update!(locale: locale)

    redirect_back fallback_location: root_path, status: :see_other
  end
end
