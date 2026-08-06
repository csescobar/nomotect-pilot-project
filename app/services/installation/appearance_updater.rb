module Installation
  class AppearanceUpdater
    def initialize(store: AppearanceStore.new, branding_store: BrandingStore.new, token_installer: DesignTokenInstaller.new)
      @store = store
      @branding_store = branding_store
      @token_installer = token_installer
    end

    def update!(attributes, uploads: {}, token_yaml: nil)
      current = @store.read
      locales = Array(attributes[:supported_locales]).reject(&:blank?).uniq
      raise ArgumentError, "At least one supported locale is required" if locales.empty?
      raise ArgumentError, "Default locale must be supported" unless locales.include?(attributes[:default_locale])

      payload = current.merge(
        "application_name" => attributes[:application_name].to_s.strip,
        "default_locale" => attributes[:default_locale],
        "supported_locales" => locales,
        "trademark_mode" => attributes[:trademark_mode].to_s.presence || "name_only"
      )
      raise ArgumentError, "Application name is required" if payload["application_name"].blank?

      if token_yaml.present?
        raise ArgumentError, "Design token editing is disabled in production" unless Configuration.token_editing_allowed?

        payload["design_tokens_sha256"] = @token_installer.install!(token_yaml)
      end

      %i[logo compact_logo favicon].each do |role|
        path = @branding_store.store(uploads[role], role: role)
        payload["#{role}_path"] = path if path
      end

      @store.write!(payload)
    end
  end
end
