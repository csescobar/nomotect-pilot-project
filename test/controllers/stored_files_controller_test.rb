require "test_helper"

class StoredFilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    suffix = SecureRandom.hex(4)
    @member = User.create!(email_address: "file-member-#{suffix}@example.com", password: "a-secure-password")
    @outsider = User.create!(email_address: "file-outsider-#{suffix}@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Files #{suffix}")
    @other_organization = Organization.create!(name: "Other files #{suffix}")
    @organization.memberships.create!(user: @member, role: "member")
    @other_organization.memberships.create!(user: @outsider, role: "member")
    @stored_file = register_file(@organization, @member, "member report")
    @other_stored_file = register_file(@other_organization, @outsider, "private report")
  end

  teardown do
    [ @stored_file, @other_stored_file ].each do |stored_file|
      EnterpriseStorage.delete(stored_file.storage_key)
    end
  end

  test "organization member downloads a tenant file" do
    sign_in(@member)

    get organization_stored_file_path(@organization, @stored_file)

    assert_response :success
    assert_equal "member report", response.body
    assert_equal "text/plain", response.media_type
    assert_match(/attachment/, response.headers["Content-Disposition"])
    assert_match(/report\.txt/, response.headers["Content-Disposition"])
  end

  test "tenant route cannot resolve a file associated with another organization" do
    sign_in(@member)

    EnterpriseStorage.stub(:read, ->(*) { flunk "unauthorized storage read" }) do
      get organization_stored_file_path(@organization, @other_stored_file)
    end

    assert_response :not_found
  end

  test "non-member cannot download a file from another organization" do
    sign_in(@member)

    EnterpriseStorage.stub(:read, ->(*) { flunk "unauthorized storage read" }) do
      get organization_stored_file_path(@other_organization, @other_stored_file)
    end

    assert_response :forbidden
  end

  private

  def register_file(organization, uploader, bytes)
    StoredFileRegistry.call(
      organization: organization,
      uploaded_by: uploader,
      name: "report.txt",
      content_type: "text/plain",
      bytes: bytes
    )
  end

  def sign_in(user)
    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]
    post session_path, params: { authenticity_token: token, email_address: user.email_address, password: "a-secure-password" }
    follow_redirect!
  end
end
