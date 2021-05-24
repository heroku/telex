require "zeus/rails"

class CustomPlan < Zeus::Rails
  def boot
    ENV["RACK_ENV"] = "test"

    require "bundler"
    Bundler.require(:default, :test)

    root = File.expand_path("../../", __FILE__)
    ENV.update(Pliny::Utils.parse_env("#{root}/.env.test"))
  end

  def test
  end

  def rspec(argv = ARGV)
    require_relative "../spec/spec_helper"
    exit RSpec::Core::Runner.run(argv)
  end

  def after_fork
    reconnect_sequel
    reconnect_redis
  end

  private

  def reconnect_sequel
    return unless defined?(Sequel)
    Sequel::DATABASES.each { |db| db.disconnect }
  end
end

Zeus.plan = CustomPlan.new
