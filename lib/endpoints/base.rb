require_relative "../redis/retry"

module Endpoints
  # The base class for all Sinatra-based endpoints. Use sparingly.
  class Base < Sinatra::Base
    register Sinatra::Namespace

    helpers Pliny::Helpers::Encode
    helpers Pliny::Helpers::Params
    helpers Pliny::Helpers::Serialize
    helpers Redis::Retry

    helpers do
      def data
        MultiJson.decode(request.body.read).tap do
          request.body.rewind
        end
      end
    end

    set :dump_errors, false
    set :raise_errors, true
    set :show_exceptions, false

    configure :development do
      register Sinatra::Reloader
      also_reload "#{Config.root}/lib/**/*.rb"
    end

    error Redis::Retry::Error do
      raise Pliny::Errors::InternalServerError
    end

    error Sinatra::NotFound, Mediators::Recipients::NotFound, Excon::Errors::NotFound do
      raise Pliny::Errors::NotFound
    end

    error Mediators::Recipients::LimitError do
      raise Pliny::Errors::TooManyRequests, sinatra_error.message
    end

    error MultiJson::ParseError do
      raise Pliny::Errors::BadRequest, "Unable to parse the JSON request"
    end

    error Sequel::UniqueConstraintViolation do
      raise Pliny::Errors::BadRequest, "A recipient with that email already exists"
    end

    error Sequel::ValidationFailed, Mediators::Recipients::BadRequest do
      raise Pliny::Errors::BadRequest, sinatra_error.message
    end

    private

    def sinatra_error
      env["sinatra.error"]
    end
  end
end
