source "https://rubygems.org"
ruby "2.1.4"

gem "excon"
gem "mail"
gem "multi_json"
gem "oj"
gem "pg"
gem "pliny"
gem "pry"
gem "pry-doc"
gem "puma"
gem "rack-ssl"
gem "rake"
gem "rollbar"
gem "sequel"
gem "sequel-paranoid"
gem "sequel_pg", require: "sequel"
gem "sidekiq"
gem "sinatra", require: "sinatra/base"
gem "sinatra-contrib", require: ["sinatra/namespace", "sinatra/reloader"]
gem "sinatra-router"
gem "sucker_punch"

group :development, :test do
  gem "pry-byebug"
end

group :development do
  gem "dotenv"
  gem "foreman"
end

group :test do
  gem "committee"
  gem "database_cleaner"
  gem "fabrication"
  gem "faker"
  gem "guard-rspec"
  gem "rack-test"
  gem "rspec"
  gem "webmock"
end
