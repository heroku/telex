module Middleware
  class ProducerAuthenticator
    def initialize(app)
      @app = app
    end

    def call(env)
      auth = Rack::Auth::Basic::Request.new(env)
      unless auth.provided? && auth.basic? && auth.credentials
        raise Pliny::Errors::Unauthorized
      end

      id, api_key = auth.credentials

      unless Pliny::Middleware::RequestID::UUID_PATTERN.match?(id)
        raise Pliny::Errors::Unauthorized
      end

      producer = Producer.find_by_creds(id: id, api_key: api_key)
      unless producer
        raise Pliny::Errors::Unauthorized
      end

      Pliny::RequestStore.store[:current_producer] = producer
      @app.call(env)
    end
  end
end
