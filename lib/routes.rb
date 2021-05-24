require "rollbar/middleware/sinatra"

Routes = Rack::Builder.new do
  use Pliny::Middleware::RequestStore::Clear
  use Pliny::Middleware::CORS
  use Pliny::Middleware::RequestID
  use Pliny::Middleware::Instruments
  use Middleware::Instrumentation
  use Pliny::Middleware::RequestStore::Seed, store: Pliny::RequestStore
  use Pliny::Middleware::RescueErrors, raise: Config.raise_errors?
  if Config.timeout > 0
    use Rack::Timeout,
      service_timeout: Config.timeout
  end
  if Config.versioning?
    use Pliny::Middleware::Versioning,
      default: Config.versioning_default,
      app_name: Config.versioning_app_name
  end
  use Rack::Deflater

  use Rack::ConditionalGet
  use Rack::ETag

  use Rack::MethodOverride
  use Rack::SSL if Config.force_ssl?

  map("/producer") do
    use Middleware::ProducerAuthenticator
    use Pliny::Router do
      mount Endpoints::ProducerAPI::Messages
      mount Endpoints::ProducerAPI::Users
    end
  end

  map("/user") do
    use Middleware::UserAuthenticator
    use Pliny::Router do
      mount Endpoints::UserAPI::Notifications
    end
  end

  map("/apps") do
    use Middleware::UserAuthenticator
    use Pliny::Router do
      mount Endpoints::AppAPI::Recipients
    end
  end

  map("/health") do
    run Endpoints::Health
  end

  # root app; but will also handle some defaults like 404
  run Endpoints::Root
end
