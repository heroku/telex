unless Config.rack_env == 'test'
  Rollbar.configure do |config|
    config.enabled = (Config.rack_env == 'production')
    config.environment = Config.console_banner || 'production'
    config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]
    config.use_sucker_punch
    # tell Rollbar to ignore internal Pliny exceptions, as these are converted
    # by the RescueErrors middleware into a standard http response:
    pliny_exceptions = ObjectSpace.each_object(::Class).select do |klass|
      klass == Pliny::Errors::Error || klass < Pliny::Errors::Error
    end
    exception_level_filters = Hash.new(
      pliny_exceptions.map { |klass| [klass.name, 'ignore'] })
    config.exception_level_filters.merge!(exception_level_filters)
  end
end
