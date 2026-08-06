require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "emits secure headers and a restrictive CSP" do
    get new_session_path

    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "DENY", response.headers["X-Frame-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
    assert_includes response.headers["Permissions-Policy"], "camera=()"

    policy = response.headers.fetch("Content-Security-Policy")
    assert_includes policy, "default-src 'self'"
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "frame-ancestors 'none'"
    assert_includes policy, "base-uri 'self'"
    assert_not_includes policy, "unsafe-inline"
  end
end
