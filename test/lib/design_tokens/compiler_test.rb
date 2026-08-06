require "test_helper"
require "tmpdir"

class DesignTokens::CompilerTest < ActiveSupport::TestCase
  test "compiles validated YAML and keeps every generated output current" do
    compiler = DesignTokens::Compiler.new

    css = compiler.compile

    assert_includes css, "[data-theme=\"dark\"]"
    assert_includes css, "--font-family-body:"
    assert_includes css, "--font-family-heading:"
    assert_includes css, "--font-family-mono:"
    assert_includes css, "--font-family-sans:"
    assert_includes css, "--line-height-heading:"
    assert_includes css, "--line-height-code:"
    assert_includes css, "--radius-full:"
    refute_includes css, "prefers-color-scheme"
    assert compiler.current?
  end

  test "a token substitution changes generated theme output without adding a public theme" do
    with_token_source(
      light: { "color.text" => "#7C2D12" },
      dark: { "color.text" => "#FDE68A" }
    ) do |compiler|
      css = compiler.compile

      assert_includes css, "--color-text: #7C2D12"
      assert_includes css, "--color-text: #FDE68A"
      assert_equal 1, css.scan(/\[data-theme="light"\]/).size
      assert_equal 1, css.scan(/\[data-theme="dark"\]/).size
    end
  end

  test "framework styles consume semantic typography roles" do
    stylesheet = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes stylesheet, "font-family: var(--font-family-body)"
    assert_includes stylesheet, "font-family: var(--font-family-heading)"
    assert_includes stylesheet, "font-family: var(--font-family-mono)"
    assert_includes stylesheet, "line-height: var(--line-height-heading)"
    assert_includes stylesheet, "line-height: var(--line-height-code)"
  end

  test "rejects divergent theme keys" do
    with_token_source(
      light: { "color.text" => "#000000" },
      dark: { "color.background" => "#000000" }
    ) do |compiler|
      assert_raises(ArgumentError) { compiler.compile }
    end
  end

  test "rejects palette color names in the public token vocabulary" do
    with_token_source(
      light: { "color.accent.blue" => "#0000FF" },
      dark: { "color.accent.blue" => "#60A5FA" }
    ) do |compiler|
      error = assert_raises(ArgumentError) { compiler.compile }

      assert_includes error.message, "semantic roles, not colors"
      assert_includes error.message, "color.accent.blue"
    end
  end

  test "rejects YAML aliases" do
    Dir.mktmpdir do |directory|
      root = Pathname(directory)
      root.join("tokens.yml").write("version: 1\nbase: &base\n  space.sm: 0.5rem\nthemes:\n  light: *base\n  dark: *base\n")
      root.join("tokens.schema.json").write(schema.to_json)

      compiler = build_compiler(root)

      error = assert_raises(ArgumentError) { compiler.compile }
      assert_includes error.message, "Invalid design token YAML"
    end
  end

  test "rejects unknown properties through the strict schema" do
    with_token_source(extra: { "unexpected" => true }) do |compiler|
      error = assert_raises(ArgumentError) { compiler.compile }
      assert_includes error.message, "$.unexpected is not allowed"
    end
  end

  private

  def with_token_source(light: default_theme, dark: default_theme, extra: {})
    Dir.mktmpdir do |directory|
      root = Pathname(directory)
      document = {
        "version" => 1,
        "base" => { "space.sm" => "0.5rem" },
        "themes" => { "light" => light, "dark" => dark }
      }.merge(extra)
      root.join("tokens.yml").write(document.to_yaml)
      root.join("tokens.schema.json").write(schema.to_json)

      yield build_compiler(root)
    end
  end

  def build_compiler(root)
    DesignTokens::Compiler.new(
      root: root,
      css_output: root.join("tokens.css"),
      ruby_output: root.join("generated.rb")
    )
  end

  def default_theme
    { "color.text" => "#000000" }
  end

  def schema
    JSON.parse(Rails.root.join("config/design_tokens/tokens.schema.json").read)
  end
end
