require "test_helper"

class GridSavedViewTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "grid-view@example.com", password: "a-secure-password")
  end

  test "keeps only one default per user and grid" do
    first = @user.grid_saved_views.create!(grid_key: "organizations", name: "First", default: true)
    second = @user.grid_saved_views.create!(grid_key: "organizations", name: "Second", default: true)

    assert_not first.reload.default?
    assert second.reload.default?
  end

  test "allows the same view name on different grids" do
    @user.grid_saved_views.create!(grid_key: "organizations", name: "Mine")

    assert @user.grid_saved_views.create(grid_key: "customers", name: "Mine").valid?
  end
end
