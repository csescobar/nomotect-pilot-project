module Marketing
  class HeaderComponent < Ui::BaseComponent
    def initialize(authenticated: false, current_user: nil, show_auth: true)
      @authenticated = authenticated
      @current_user = current_user
      @show_auth = show_auth
    end
  end
end
