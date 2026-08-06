require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "owner@example.com", password: "a-secure-password")
    @member = User.create!(email_address: "member@example.com", password: "a-secure-password")
    @outsider = User.create!(email_address: "outsider@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @organization.memberships.create!(user: @owner, role: "owner")
    @organization.memberships.create!(user: @member, role: "member")
    @customer = @organization.customers.create!(name: "Ada", email_address: "ada@example.com")
  end

  test "member can view customer index" do
    sign_in(@member)

    get organization_customers_path(@organization)

    assert_response :success
    assert_select "a", text: "Ada"
    assert_select ".responsive-data-table .ui-badge--success", text: "Active"
    assert_select "td[data-label='Name']", text: /Ada/
    assert_select "td[data-label='Email']", text: "ada@example.com"
  end

  test "customer details use property, empty-state and status components" do
    sign_in(@member)

    get organization_customer_path(@organization, @customer)

    assert_response :success
    assert_select ".ui-property-list .ui-badge--success", text: "Active"
    assert_select ".ui-empty-state", text: /No audit events yet/
    assert_select ".ui-danger-zone", count: 0
  end

  test "owner sees a separate danger zone and tokenized textarea" do
    sign_in(@owner)

    get organization_customer_path(@organization, @customer)
    assert_select ".ui-danger-zone", text: /Delete customer/

    get edit_organization_customer_path(@organization, @customer)
    assert_response :success
    assert_select "textarea.ui-input#customer_notes"
  end

  test "owner creates a customer through domain operation" do
    sign_in(@owner)

    assert_difference [ "Customer.count", "DomainEvent.count" ], 1 do
      post organization_customers_path(@organization), params: {
        authenticity_token: csrf_token,
        customer: { name: "Grace", email_address: "grace@example.com", status: "active" }
      }
    end

    assert_redirected_to organization_customer_path(@organization, Customer.last)
  end

  test "regular member cannot create a customer" do
    sign_in(@member)

    assert_no_difference "Customer.count" do
      post organization_customers_path(@organization), params: {
        authenticity_token: csrf_token,
        customer: { name: "Grace", status: "active" }
      }
    end

    assert_response :forbidden
  end

  test "outsider cannot access organization customers" do
    sign_in(@outsider)

    get organization_customers_path(@organization)

    assert_response :forbidden
  end

  test "stale update returns conflict" do
    sign_in(@owner)
    stale_version = @customer.lock_version
    @customer.update!(name: "Changed elsewhere")

    patch organization_customer_path(@organization, @customer), params: {
      authenticity_token: csrf_token,
      customer: { name: "Stale edit", status: "active", lock_version: stale_version }
    }

    assert_response :conflict
    assert_equal "Changed elsewhere", @customer.reload.name
  end

  private

  def sign_in(user)
    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]
    post session_path, params: { authenticity_token: token, email_address: user.email_address, password: "a-secure-password" }
    follow_redirect!
  end

  def csrf_token
    Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
  end
end
