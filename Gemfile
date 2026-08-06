source "https://rubygems.org"

ruby "~> 4.0.5"

gem "rails", "~> 8.1.3", ">= 8.1.3.1"
gem "pg", "~> 1.6"
gem "puma", ">= 6.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bootsnap", require: false
gem "bcrypt", "~> 3.1"
gem "view_component"
gem "rack-attack"
gem "csv"
gem "rubyzip", "~> 3.4", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
  gem "kamal", "~> 2.12", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "cuprite"
end
