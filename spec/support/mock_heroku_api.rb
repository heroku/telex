require "webmock"

module HerokuAPIMock
  include WebMock::API

  HerokuMockUser = Struct.new(:heroku_id, :email, :api_key)

  def create_heroku_user
    user = HerokuMockUser.new(SecureRandom.uuid, Faker::Internet.email, SecureRandom.uuid)

    user_response = MultiJson.encode({
      "email" => user.email,
      "id" => user.heroku_id,
      "last_login" => Time.now.utc.iso8601,
    })

    # intended for user finder, looking up current email address using telex's key
    stub_heroku_api_request(:get, "#{Config.heroku_api_url}/account")
      .with(headers: {"User" => user.heroku_id})
      .to_return(body: user_response)

    # intended for user api auth using the user's token
    stub_heroku_api_request(:get, "#{Config.heroku_api_url}/account", api_key: user.api_key)
      .to_return(body: user_response)

    user
  end

  HerokuMockApp = Struct.new(:id, :owner, :collaborators)

  def create_heroku_app(owner:, collaborators: [], id: SecureRandom.uuid)
    app = HerokuMockApp.new(id, owner, collaborators)
    app_response = {
      "name" => "example",
      "owner" => {
        "email" => owner.email,
        "id" => owner.heroku_id,
      },
    }
    stub_heroku_api_request(:get, "#{Config.heroku_api_url}/apps/#{app.id}")
      .to_return(body: MultiJson.encode(app_response))

    collab_response = collaborators.map { |user|
      {
        "created_at" => "2012-01-01T12:00:00Z",
        "id" => SecureRandom.uuid,
        "updated_at" => "2012-01-01T12:00:00Z",
        "user" => {
          "email" => user.email,
          "id" => user.heroku_id,
          "two_factor_authentication" => false,
        },
      }
    }

    stub_heroku_api_request(:get, "#{Config.heroku_api_url}/apps/#{app.id}/collaborators")
      .to_return(body: MultiJson.encode(collab_response))

    app
  end

  # If you call create_heroku_app with an existing app id and different owners or collabs than
  # what's already associated with the app, it will rewrite the mocked
  # responses for that app id to reflect the change in ownership or
  # collaborators.

  # This method calls create to rewrite the mocked collab response for a given app,
  # with the goal of being more obvious that an update is happening, rather than
  # calling create_heroku_app twice in the same test.
  def update_app_collaborators(app, collaborators)
    create_heroku_app(id: app.id, collaborators: collaborators, owner: app.owner)
  end

  def stub_heroku_api_request(method, url, api_key: nil)
    api_config = Addressable::URI.parse(url)
    api_config.password = api_key if api_key

    # Strip Basic auth from URL since Excon will send it as an AUTHORIZATION header, so Webmock won't match the request.
    heroku_api_uri = api_config.dup.tap { |uri| uri.userinfo = nil }

    stub_request(method, heroku_api_uri)
      .with(basic_auth: [api_config.user, api_config.password])
  end
end
