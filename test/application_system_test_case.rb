require "test_helper"
require "capybara/cuprite"

# ApplicationSystemTestCase — Phase 6 Real-Browser Automation
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :chrome, screen_size: [ 1400, 900 ], options: {
    js_errors: true,
    browser_options: { "no-sandbox": nil, "disable-gpu": nil },
    process_timeout: 15,
    timeout: 10
  }
end
