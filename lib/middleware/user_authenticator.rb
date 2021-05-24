require_relative "../redis/retry"

module Middleware
  class UserAuthenticator
    include Redis::Retry

    def initialize(app)
      @app = app
    end

    def call(env)
      authenticate_user env unless skip_auth?(env)
      @app.call(env)
    end

    private

    def authenticate_user(env)
      redis_retry do
        api_key = parse_api_key(env)
        raise Pliny::Errors::Unauthorized unless api_key

        user = lookup_user(key: api_key)
        raise Pliny::Errors::Unauthorized unless user

        Pliny::RequestStore.store[:heroku_client] = Telex::HerokuClient.new(api_key: api_key)
        Pliny::RequestStore.store[:current_user] = user
      end
    end

    def parse_api_key(env)
      bearer_token(env) || basic_auth_password(env)
    end

    def bearer_token(env)
      env["HTTP_AUTHORIZATION"].to_s[/\ABearer\s+(\S+)\z/, 1]
    end

    def basic_auth_password(env)
      auth = Rack::Auth::Basic::Request.new(env)
      auth.provided? && auth.basic? && auth.credentials&.last
    end

    def skip_auth?(env)
      env["PATH_INFO"]&.end_with?("/read.png")
    end

    def lookup_user(key:)
      return nil unless Pliny::Middleware::RequestID::UUID_PATTERN === key

      cache_find(key: key) || api_find(key: key)
    end

    def api_find(key:)
      client = Telex::HerokuClient.new(api_key: key)
      user_response = client.account_info

      user = find_or_create_user(
        heroku_id: user_response.fetch("id"),
        email: user_response.fetch("email")
      )

      cache_store user_id: user.id, key: key

      user
    rescue Excon::Errors::Error, Telex::HerokuClient::NotFound
      nil
    end

    def find_or_create_user(heroku_id:, email:)
      User[heroku_id: heroku_id] || User.create(heroku_id: heroku_id, email: email)
    end

    def cache_find(key:)
      return unless Config.cache_user_auth?
      id = Sidekiq.redis { |r| r.get("keycache.#{hmac(key)}") }
      User[id: id]
    end

    def cache_store(user_id:, key:)
      return unless Config.cache_user_auth?
      Sidekiq.redis { |r| r.setex("keycache.#{hmac(key)}", 3600, user_id) }
    end

    def hmac(raw_key)
      OpenSSL::HMAC.hexdigest("sha512", Config.api_key_hmac_secret, raw_key)
    end
  end
end
