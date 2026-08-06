require "test_helper"

class GridEngine::SyncfusionAdapterTest < ActiveSupport::TestCase
  # Fixture: definição de grid de teste, idêntica ao padrão do GridEngine::Catalog
  setup do
    @definition = GridEngine::Definition.new(key: :test_entities, model_class: Organization) do
      column :name,       type: :string,   label: "Name"
      column :score,      type: :integer
      column :rate,       type: :decimal
      column :active,     type: :boolean
      column :created_at, type: :datetime
      column :born_on,    type: :date
    end
    @adapter = GridEngine::SyncfusionAdapter.new(@definition)
  end

  # ---------------------------------------------------------------------------
  # columns
  # ---------------------------------------------------------------------------

  test "columns returns one entry per defined column" do
    assert_equal @definition.columns.size, @adapter.columns.size
  end

  test "columns includes required EJ2 keys for each column" do
    @adapter.columns.each do |col|
      assert col.key?(:field),         "missing :field in #{col.inspect}"
      assert col.key?(:headerText),    "missing :headerText in #{col.inspect}"
      assert col.key?(:visible),       "missing :visible in #{col.inspect}"
      assert col.key?(:allowSorting),  "missing :allowSorting in #{col.inspect}"
      assert col.key?(:allowFiltering), "missing :allowFiltering in #{col.inspect}"
      assert col.key?(:type),          "missing :type in #{col.inspect}"
    end
  end

  test "columns uses column key as field" do
    name_col = @adapter.columns.find { |c| c[:field] == "name" }
    assert_not_nil name_col, "Expected a column with field 'name'"
  end

  test "columns uses explicit label when provided" do
    name_col = @adapter.columns.find { |c| c[:field] == "name" }
    assert_equal "Name", name_col[:headerText]
  end

  test "columns falls back to humanized key when no label is provided" do
    score_col = @adapter.columns.find { |c| c[:field] == "score" }
    # label_for falls back to I18n or humanize — just assert it's a non-empty string
    assert_kind_of String, score_col[:headerText]
    assert_not_empty score_col[:headerText]
  end

  test "columns propagates sortable flag" do
    definition = GridEngine::Definition.new(key: :unsortable_test, model_class: Organization) do
      column :name, type: :string, sortable: false
    end
    col = GridEngine::SyncfusionAdapter.new(definition).columns.first
    assert_equal false, col[:allowSorting]
  end

  test "columns propagates filterable flag" do
    definition = GridEngine::Definition.new(key: :unfilterable_test, model_class: Organization) do
      column :name, type: :string, filterable: false
    end
    col = GridEngine::SyncfusionAdapter.new(definition).columns.first
    assert_equal false, col[:allowFiltering]
  end

  test "columns propagates visible flag" do
    definition = GridEngine::Definition.new(key: :invisible_test, model_class: Organization) do
      column :name, type: :string, visible: false
    end
    col = GridEngine::SyncfusionAdapter.new(definition).columns.first
    assert_equal false, col[:visible]
  end

  # ---------------------------------------------------------------------------
  # EJ2 type mapping
  # ---------------------------------------------------------------------------

  test "maps string type to EJ2 string" do
    col = @adapter.columns.find { |c| c[:field] == "name" }
    assert_equal "string", col[:type]
  end

  test "maps integer type to EJ2 number" do
    col = @adapter.columns.find { |c| c[:field] == "score" }
    assert_equal "number", col[:type]
  end

  test "maps decimal type to EJ2 number" do
    col = @adapter.columns.find { |c| c[:field] == "rate" }
    assert_equal "number", col[:type]
  end

  test "maps boolean type to EJ2 boolean" do
    col = @adapter.columns.find { |c| c[:field] == "active" }
    assert_equal "boolean", col[:type]
  end

  test "maps datetime type to EJ2 datetime" do
    col = @adapter.columns.find { |c| c[:field] == "created_at" }
    assert_equal "datetime", col[:type]
  end

  test "maps date type to EJ2 date" do
    col = @adapter.columns.find { |c| c[:field] == "born_on" }
    assert_equal "date", col[:type]
  end

  test "unknown type falls back to EJ2 string" do
    # Arrange: insert an unknown type directly in the registry temporarily
    # via a definition that has already had its type validated at column() time.
    # We test ej2_type_for indirectly by stubbing the column type value.
    definition = GridEngine::Definition.new(key: :fallback_test, model_class: Organization) do
      column :name, type: :string
    end
    adapter = GridEngine::SyncfusionAdapter.new(definition)
    # Patch the private method via send for edge-case coverage
    assert_equal "string", adapter.send(:ej2_type_for, "completely_unknown")
  end

  # ---------------------------------------------------------------------------
  # response
  # ---------------------------------------------------------------------------

  test "response returns a hash with :result and :count keys" do
    result = mock_result(records: [], total_count: 0)
    response = @adapter.response(result)

    assert response.key?(:result), "response missing :result"
    assert response.key?(:count),  "response missing :count"
  end

  test "response :result is an array" do
    result = mock_result(records: [], total_count: 0)
    assert_kind_of Array, @adapter.response(result)[:result]
  end

  test "response :count equals total_count from result" do
    result = mock_result(records: [], total_count: 42)
    assert_equal 42, @adapter.response(result)[:count]
  end

  test "response serializes each record with column keys" do
    org = Organization.create!(name: "Acme Test Corp")
    result = mock_result(records: [ org ], total_count: 1)
    serialized = @adapter.response(result)[:result].first

    assert serialized.key?("name"),       "serialized record missing 'name'"
    assert serialized.key?("created_at"), "serialized record missing 'created_at'"
  end

  test "response serializes the correct attribute values" do
    org = Organization.create!(name: "Acme Values Corp")
    result = mock_result(records: [ org ], total_count: 1)
    serialized = @adapter.response(result)[:result].first

    assert_equal org.name, serialized["name"]
  end

  test "response does not include extra keys beyond column definitions" do
    org = Organization.create!(name: "Acme Extra Corp")
    result = mock_result(records: [ org ], total_count: 1)
    serialized = @adapter.response(result)[:result].first

    allowed_keys = @definition.columns.keys
    extra_keys = serialized.keys - allowed_keys
    assert_empty extra_keys, "Unexpected extra keys in serialized record: #{extra_keys}"
  end

  test "response handles multiple records" do
    orgs = 3.times.map { |i| Organization.create!(name: "Org #{i}") }
    result = mock_result(records: orgs, total_count: orgs.size)
    response = @adapter.response(result)

    assert_equal orgs.size, response[:result].size
    assert_equal orgs.size, response[:count]
  end

  test "filter_choice_response returns distinct field values for filter popup" do
    orgs = [ Organization.create!(name: "Acme"), Organization.create!(name: "Acme") ]
    result = mock_result(records: orgs, total_count: 2)
    response = @adapter.filter_choice_response(result, field: "name")

    assert_equal 1, response[:result].size
    assert_equal "Acme", response[:result].first["name"]
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  private

  # Builds a lightweight result double that mimics GridEngine::ActiveRecordAdapter output
  def mock_result(records:, total_count:)
    Struct.new(:records, :total_count).new(records, total_count)
  end
end
