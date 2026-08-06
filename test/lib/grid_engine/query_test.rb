require "test_helper"

class GridEngineQueryTest < ActiveSupport::TestCase
  setup do
    @definition = GridEngine::Definition.new(key: :users, model_class: User) do
      column :email_address, type: :string
      column :created_at, type: :datetime
      column :password_digest, type: :string, filterable: false, visible: false
      sort :email_address
    end
  end

  test "defines typed columns" do
    assert_equal "string", @definition.fetch_column(:email_address).type
    assert_equal [ [ "email_address", "asc" ] ], @definition.default_sort
  end

  test "parses filters, sorts, and pagination" do
    ast = GridEngine::Query::Parser.new(@definition).parse(
      filters: [ { column: "email_address", operator: "contains", value: "example" } ],
      sorts: [ { column: "created_at", direction: "desc" } ],
      page: "2",
      per_page: "50"
    )

    assert_equal "contains", ast.filters.first.operator
    assert_equal "desc", ast.sorts.first.direction
    assert_equal 2, ast.page
    assert_equal 50, ast.per_page
  end

  test "rejects filters on protected columns" do
    error = assert_raises(GridEngine::Query::ValidationError) do
      GridEngine::Query::Parser.new(@definition).parse(
        filters: [ { column: "password_digest", operator: "eq", value: "secret" } ]
      )
    end

    assert_match "not filterable", error.message
  end

  test "caps page size" do
    ast = GridEngine::Query::Parser.new(@definition).parse(per_page: 10_000)
    assert_equal 250, ast.per_page
  end
end
