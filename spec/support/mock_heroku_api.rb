require 'webmock'
module HerokuAPIMock
  include WebMock::API
  extend self

  HerokuMockUser = Struct.new(:heroku_id, :email, :api_key)
  def create_heroku_user
    user = HerokuMockUser.new(SecureRandom.uuid, Faker::Internet.email, SecureRandom.uuid)

    user_response = MultiJson.encode({
      "email"      => user.email,
      "id"         => user.heroku_id,
      "last_login" => Time.now.utc.iso8601
    })

    # intended for user finder, looking up current email address using telex's key
    stub_request(:get, "#{Config.heroku_api_url}/account")
      .with(headers: {"User" => user.heroku_id})
      .to_return(body: user_response)

    # intended for user api auth using the user's token
    stub_request(:get, "https://telex:#{user.api_key}@api.heroku.com/account")
      .to_return(body: user_response)

    return user
  end

  HerokuMockApp = Struct.new(:id)
  def create_heroku_app(name: "example", owner:, collaborators:[])
    app = HerokuMockApp.new(SecureRandom.uuid)
    app_response = {
      "name" => name,
        "owner" => {
          "email" => owner.email,
          "id" => owner.heroku_id
         }
    }
    stub_request(:get, "#{Config.heroku_api_url}/apps/#{app.id}")
      .to_return(body: MultiJson.encode(app_response))

    collab_response = collaborators.map do |user|
      {
        "created_at" => "2012-01-01T12:00:00Z",
        "id" => SecureRandom.uuid,
        "updated_at" => "2012-01-01T12:00:00Z",
        "user" => {
          "email" => user.email,
          "id" => user.heroku_id,
          "two_factor_authentication" => false
        }
      }
    end
    stub_request(:get, "#{Config.heroku_api_url}/apps/#{app.id}/collaborators")
      .to_return( body: MultiJson.encode(collab_response) )

    return app
  end
end
