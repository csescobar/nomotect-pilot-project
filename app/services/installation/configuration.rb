module Installation
  module Configuration
    module_function

    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("INSTALLATION_ENABLED", "false"))
    end

    def production_token_required?
      Rails.env.production?
    end

    def token_editing_allowed?
      return true unless Rails.env.production?

      ActiveModel::Type::Boolean.new.cast(ENV.fetch("INSTALLATION_ALLOW_TOKEN_EDITING", "false"))
    end
  end
end
