module ApplicationHelper
  # Returns the raw appearance configuration Hash from AppearanceStore.
  def platform_appearance
    @_platform_appearance ||= begin
      Installation::AppearanceStore.new.read
    rescue StandardError
      {}
    end
  end

  # Returns the configured platform name from AppearanceStore,
  # falling back to I18n.t("application.name").
  def platform_name
    @_platform_name ||= platform_appearance["application_name"].presence || I18n.t("application.name")
  end

  # Renders the trademark / brand element according to trademark_mode setting:
  # - "name_only": platform name text
  # - "image_only": logo image (if present), fallback to platform name text
  # - "image_and_name": logo image + platform name text
  def platform_brand_tag(css_class: "brand-mark")
    appearance = platform_appearance
    mode = appearance["trademark_mode"] || "name_only"
    logo_path = appearance["logo_path"].presence

    case mode
    when "image_only"
      if logo_path
        image_tag(logo_path, alt: platform_name, class: "#{css_class}__logo")
      else
        tag.span(platform_name, class: "#{css_class}__name")
      end
    when "image_and_name"
      if logo_path
        safe_join([
          image_tag(logo_path, alt: "", class: "#{css_class}__logo"),
          tag.span(platform_name, class: "#{css_class}__name")
        ], " ")
      else
        tag.span(platform_name, class: "#{css_class}__name")
      end
    else # name_only
      tag.span(platform_name, class: "#{css_class}__name")
    end
  end

  # Renders the platform favicon tag based on AppearanceStore configuration.
  def platform_favicon_tag
    appearance = platform_appearance
    favicon_path = appearance["favicon_path"].presence || appearance["compact_logo_path"].presence || "/favicon.svg"
    options = favicon_path.end_with?(".svg") ? { type: "image/svg+xml" } : {}

    favicon_link_tag(favicon_path, **options)
  end
end
