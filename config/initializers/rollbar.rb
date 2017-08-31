unless Config.rack_env == 'test'
  Rollbar.configure do |config|
    config.enabled = (Config.rack_env == 'production')
    config.environment = Config.console_banner || 'production'
    config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]
    config.logger = Pliny::RollbarLogger.new
    config.use_sucker_punch
    config.disable_monkey_patch = true
    config.root = Config.root

    config.scrub_fields  |= Rollbar::Blanket.fields
    config.scrub_headers |= Rollbar::Blanket.headers

    config.exception_level_filters.merge!(
      "Telex::Emailer::DeliveryError" => "warning",
      "Pliny::Errors::HTTPStatusError" => "ignore"
    )
  end
end
