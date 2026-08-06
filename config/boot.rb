ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"

# Load .env before Rails initializes so DATABASE_URL and other env vars are available
# to all processes (test suite, CI sub-scripts, rake tasks, etc.)
begin
  require "dotenv"
  Dotenv.load(File.expand_path("../.env", __dir__))
rescue LoadError
  # dotenv not available in this environment — rely on shell-level env vars
end

require "bootsnap/setup"
