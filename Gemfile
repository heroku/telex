source "https://rubygems.org"

ruby "2.6.6"

gem "clockwork"
gem "erubis"
gem "excon"
gem "mail"
gem "multi_json"
gem "oj"
gem "pg"
gem "pliny", "~> 0.27", ">= 0.27.1"
gem "pry", require: false # Make Pry available in production `heroku console` sessions
gem "pry-doc", require: false
gem "puma", "~> 3.12", ">= 3.12.6"
gem "rack-ssl", ">= 1.4.1"
gem "rack-timeout", "~> 0.4"
gem "rake"
gem "redcarpet", ">= 3.5.1"
gem "rollbar"
gem "sequel", "~> 4.30"
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
  gem "addressable"
  gem "committee", ">= 3.0.1"
  gem "database_cleaner-sequel"
  gem "fabrication"
  gem "faker"
  gem "guard-rspec"
  gem "rack-test", ">= 1.1.0"
  gem "rspec"
  gem "webmock", "~> 3.12", ">= 3.12.1"
end
