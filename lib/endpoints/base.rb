module Endpoints
  # The base class for all Sinatra-based endpoints. Use sparingly.
  class Base < Sinatra::Base
    register Pliny::Extensions::Instruments
    register Sinatra::Namespace
    register Sinatra::Schema

    helpers Pliny::Helpers::Encode
    helpers Pliny::Helpers::Params

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
      also_reload '../**/*.rb'
    end

    error Pliny::Errors::Error do
      Pliny::Errors::Error.render(env["sinatra.error"])
    end

    not_found do
      content_type :json
      status 404
      "{}"
    end
  end
end
