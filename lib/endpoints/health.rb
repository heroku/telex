module Endpoints
  class Health < Base
    get "/" do
      check_database
      check_api_key
      ""
    end

    private

    def check_database
      Sequel::Model.db.execute("SELECT 1")
    rescue Sequel::DatabaseError
      halt 503
    end

    def check_api_key
      Telex::HerokuClient.new.account_info
    rescue Pliny::Errors::Unauthorized, Pliny::Errors::Forbidden
      # our API key is bad! fail the health check so we get alerted:
      halt 503
    rescue Excon::Errors::Error
      # generic error talking to the API, assume we're ok as the API
      # team should be getting paged for this. in the meantime our
      # jobs will continue to retry
    end
  end
end
