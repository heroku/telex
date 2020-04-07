source "https://rubygems.org"

ruby "2.6.6"

gem "clockwork"
gem "erubis"
gem "excon"
gem "mail"
gem "multi_json"
gem "oj"
gem "pg"
gem "pliny", "~> 0.16"
gem "pry", require: false # Make Pry available in production `heroku console` sessions
gem "pry-doc", require: false
gem "puma", "~> 3.11"
gem "rack-ssl"
gem "rack-timeout", "~> 0.4"
gem "rake"
gem "redcarpet"
gem "rollbar"
gem "sequel", "~> 4.30"
gem "sequel-paranoid"
gem "sequel_pg", require: "sequel"
gem "sidekiq"
gem "sinatra", "~> 1.4", require: "sinatra/base"
gem "sinatra-contrib", require: ["sinatra/namespace", "sinatra/reloader"]
gem "sinatra-router"
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
  gem "committee"
  gem "database_cleaner"
  gem "fabrication"
  gem "faker"
  gem "guard-rspec"
  gem "rack-test"
  gem "rspec"
  gem "webmock", "~> 3.5"
end
