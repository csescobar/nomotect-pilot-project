require "test_helper"

class GridsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "grid@example.com", password: "a-secure-password")
    @visible = Organization.create!(name: "Visible Organization")
    @visible.memberships.create!(user: @user, role: "member")
    @hidden = Organization.create!(name: "Hidden Organization")
    sign_in(@user)
  end

  test "renders only records in the authenticated scope" do
    get grid_path("organizations")

    assert_response :success
    assert_select "td", text: @visible.name
    assert_select "td", text: @hidden.name, count: 0
    assert_select "table.grid-engine-table"
    assert_select "td", text: I18n.l(@visible.created_at, format: :short)
  end

  test "returns a Tabulator-compatible response" do
    get grid_path("organizations", format: :json)

    assert_response :success
    payload = response.parsed_body
    assert_equal 1, payload.fetch("last_page")
    assert_equal @visible.name, payload.fetch("data").first.fetch("name")
  end

  test "exports only records in the authenticated scope" do
    get grid_path("organizations", format: :csv)

    assert_response :success
    assert_includes response.body, @visible.name
    assert_not_includes response.body, @hidden.name
    assert_includes response.body, @visible.created_at.iso8601
  end

  test "resolves column labels in the current request locale" do
    @user.update!(locale: "pt-BR")
    get grid_path("organizations")

    assert_response :success
    assert_select "th", text: "Nome"
    assert_select "th", text: "Identificador"
    assert_select "body", text: /Translation missing/, count: 0
  end

  test "exports localized column labels" do
    @user.update!(locale: "pt-BR")
    get grid_path("organizations", format: :csv)

    assert_response :success
    assert_includes response.body, "Nome,Identificador,Criada em"
  end

  test "rejects unknown columns" do
    get grid_path("organizations"), params: {
      filters: [ { column: "password_digest", operator: "equals", value: "secret" } ]
    }

    assert_response :unprocessable_content
  end

  private

  def sign_in(user)
    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]
    post session_path, params: {
      authenticity_token: token,
      email_address: user.email_address,
      password: "a-secure-password"
    }
    follow_redirect!
  end
end
