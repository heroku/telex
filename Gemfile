source "https://rubygems.org"

ruby "2.7.3"

gem "clockwork"
gem "erubis"
gem "excon", "~> 0.79.0" # Need upstream fix for DNS resolution: https://github.com/excon/excon/issues/747#issuecomment-840770108
gem "mail"
gem "multi_json"
gem "oj"
gem "pg"
gem "pliny", "~> 0.27", ">= 0.27.1"
gem "pry", require: false # Make Pry available in production `heroku console` sessions
gem "pry-doc", require: false
gem "puma", "~> 5.3"
gem "rack-ssl", ">= 1.4.1"
gem "rack-timeout", "~> 0.4"
gem "rake"
gem "redcarpet", ">= 3.5.1"
gem "rollbar"
gem "sequel", "~> 5.9"
gem "sequel-paranoid"
gem "sequel_pg", require: "sequel"
gem "sidekiq", ">= 5.2.5"
gem "sinatra", "~> 2.0", ">= 2.0.0", require: "sinatra/base"
gem "sinatra-contrib", "~> 2.0", require: ["sinatra/namespace", "sinatra/reloader"]
gem "sinatra-router", ">= 0.2.4"
gem "sucker_punch"

source "https://packagecloud.io/heroku/gemgate/" do
  gem "blacklist_hash", "~> 2.0.0"
  gem "rollbar-blanket", "~> 1.0.0"
end

group :development, :test do
  gem "pry-byebug"
end

group :development do
  gem "dotenv"
end

group :test do
  gem "addressable", ">= 2.8.0"
  gem "committee", ">= 3.0.1"
  gem "database_cleaner-sequel"
  gem "fabrication"
  gem "faker"
  gem "guard-rspec"
  gem "rack-test", ">= 1.1.0"
  gem "rspec"
  gem "webmock", "~> 3.13", ">= 3.13.0"
end
