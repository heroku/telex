ENV["RACK_ENV"] = "test"
ENV["REDIS_RETRY_IN_SECONDS"] = "0.1"

require "bundler"
Bundler.require(:default, :test, :development)

require "dotenv"
Dotenv.load(".env.test")

require_relative "../config/config"
require_relative "../lib/initializer"

require "sidekiq/testing"
require "webmock/rspec"
# pull in test initializers
Pliny::Utils.require_glob("#{Config.root}/spec/support/**/*.rb")

RSpec.configure do |config|
  config.before :suite do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.before :all do
    load("db/seeds.rb") if File.exist?("db/seeds.rb")
  end

  config.before :each do
    Mail::TestMailer.deliveries.clear
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
    Sidekiq::Worker.clear_all
  end

  config.expect_with :rspec
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/failures.txt"
  config.disable_monkey_patching!
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  # the rack app to be tested with rack-test:
  def app
    @rack_app || fail("Missing @rack_app")
  end
end
