require "uri"
module Telex
  class HerokuClient
    class BadResponse < StandardError; end

    class NotFound < StandardError; end

    attr_accessor :uri
    private :uri=

    def initialize(api_key: nil)
      self.uri = URI.parse(Config.heroku_api_url)
      if api_key
        uri.password = api_key
      end
    end

    def account_info(user_uuid: nil)
      if user_uuid
        get("/account", user: user_uuid)
      else
        get("/account", base_headers_only: true)
      end
    end

    # capable? supports only one type/id parameter in the payload,
    # and returns the corresponding capable: attribute in the payload.
    def capable?(type:, id:, capability:, base_headers_only: true)
      body = {
        "capabilities" => [
          "capability" => capability,
          "resource_id" => id,
          "resource_type" => type
        ]
      }
      response = put(
        "/users/~/capabilities",
        variant: ".capabilities",
        base_headers_only: base_headers_only,
        body: body.to_json
      )

      raise BadResponse unless response["capabilities"].is_a?(Array)
      raise BadResponse unless response["capabilities"][0].is_a?(Hash)

      response["capabilities"][0]["capable"]
    end

    def app_info(app_uuid, base_headers_only: false)
      get("/apps/#{app_uuid}", base_headers_only: base_headers_only)
    end

    def app_collaborators(app_uuid)
      get("/apps/#{app_uuid}/collaborators")
    end

    def team_members(team_name)
      get("/teams/#{team_name}/members")
    end

    private

    def client
      @client ||= Excon.new(uri.to_s)
    end

    def headers(base_headers_only: false, user: nil, range: nil, variant: nil)
      range = "id ..; max=1000;" if range.nil?

      base = {
        "Accept" => "application/vnd.heroku+json; version=3#{variant}",
        "User-Agent" => "telex",
        "X-Heroku-Requester" => "Telex",
        "Range" => range
      }

      request_id = Pliny::RequestStore.store[:request_id]
      base["Request-Id"] = request_id if request_id

      if base_headers_only
        base
      else
        base.merge(additional_headers(user: user))
      end
    end

    def additional_headers(user: nil)
      return {} unless Config.additional_api_headers
      template = MultiJson.decode(Config.additional_api_headers)
      if user
        template.map { |(k, v)| [k, v.sub("{{user}}", user)] }.to_h
      else
        template.reject { |k, v| v == "{{user}}" }
      end
    end

    def get(path, options = {})
      response = client.get(
        expects: [200, 206],
        headers: headers(options),
        path: path
      )
      content = MultiJson.decode(response.body)

      if more_data? response
        opts = {range: response.headers["Next-Range"]}.merge(options)
        content.concat get(path, opts)
      end

      content
    rescue => err
      handle_error(err)
    end

    def put(path, options = {})
      response = client.put(
        expects: [200, 206],
        body: options.delete(:body),
        headers: headers(options),
        path: path
      )

      MultiJson.decode(response.body)
    rescue => err
      handle_error(err)
    end

    def more_data?(response)
      response.status == 206 && response.headers.key?("Next-Range")
    end

    def handle_error(error)
      case error
      when Excon::Errors::NotFound
        raise Telex::HerokuClient::NotFound
      when Excon::Errors::Unauthorized
        raise Pliny::Errors::Unauthorized
      when Excon::Errors::Forbidden
        raise Pliny::Errors::Forbidden
      else
        raise error
      end
    end
  end
end
