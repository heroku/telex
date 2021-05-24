RSpec.describe Telex::HerokuClient, "#new" do
  include HerokuAPIMock

  let(:client) { Telex::HerokuClient.new }

  it "uses config for the default uri" do
    uri_string = client.uri.to_s
    expect(uri_string).to eq(Config.heroku_api_url)
    expect(uri_string).to_not be_blank
  end

  it "allows subsutition of another api key" do
    key = SecureRandom.uuid
    uri = Telex::HerokuClient.new(api_key: key).uri
    expect(uri.to_s).to_not eq(Config.heroku_api_url)
    expect(uri.password).to eq(key)
  end

  it "passes the current request-id" do
    Pliny::RequestStore.store[:request_id] = "12345"

    stub_heroku_api_request(:get, "#{client.uri}/teams/foobar/members")
      .with(headers: {"Request-Id" => "12345"})
      .to_return(status: 200, body: [{"id" => 1}].to_json)

    expect(client.team_members("foobar")).to eql([{"id" => 1}])
  end

  it "handles requests" do
    stub_heroku_api_request(:get, "#{client.uri}/teams/foobar/members")
      .to_return(status: 200, body: [{"id" => 1}].to_json)

    expect(client.team_members("foobar")).to eql([{"id" => 1}])
  end

  it "handles ranges" do
    stub_heroku_api_request(:get, "#{client.uri}/teams/foobar/members")
      .with(headers: {"Range" => "id ..; max=1000;"})
      .to_return(
        status: 206,
        body: [{"id" => 1}].to_json,
        headers: {
          "Next-Range" => "]1..; max=1000;"
        }
      )

    stub_heroku_api_request(:get, "#{client.uri}/teams/foobar/members")
      .with(headers: {"Range" => "]1..; max=1000;"})
      .to_return(status: 206, body: [{"id" => 2}].to_json)

    expect(client.team_members("foobar")).to eql([{"id" => 1}, {"id" => 2}])
  end

  it "raises a NotFound error on 404s" do
    stub_heroku_api_request(:get, "#{client.uri}/teams/foobar/members")
      .to_return(status: 404)

    expect { client.team_members("foobar") }
      .to(raise_error(Telex::HerokuClient::NotFound))
  end

  describe "capabilities endpoint" do
    it "returns true/false from matching response" do
      id = SecureRandom.uuid

      responses = [
        ['{ "capabilities": [{"capable": true}] }', true],
        ['{ "capabilities": [{"capable": false}] }', false]
      ]

      responses.each do |payload, capable|
        stub_heroku_api_request(:put, "#{client.uri}/users/~/capabilities")
          .with(
            body: {
              capabilities: [{
                capability: "view_metrics",
                resource_id: id,
                resource_type: "app"
              }]
            }.to_json
          ).to_return(status: 200, body: payload, headers: {})

        expect(client.capable?(type: "app", id: id, capability: "view_metrics")).to eql(capable)
      end
    end

    it "throws bad response on incomplete JSON payload response" do
      id = SecureRandom.uuid

      bad_responses = [
        "{}",
        '{ "capabilities": null }',
        '{ "capabilities": [] }'
      ]

      bad_responses.each do |bad_response|
        stub_heroku_api_request(:put, "#{client.uri}/users/~/capabilities")
          .with(
            body: {
              capabilities: [{
                capability: "view_metrics",
                resource_id: id,
                resource_type: "app"
              }]
            }.to_json
          ).to_return(status: 200, body: bad_response, headers: {})

        expect { client.capable?(type: "app", id: id, capability: "view_metrics") }
          .to(raise_error(Telex::HerokuClient::BadResponse))
      end
    end

    it "throws unauthorized on a 401 response" do
      stub_heroku_api_request(:put, "#{client.uri}/users/~/capabilities")
        .to_return(status: 401, body: "", headers: {})

      expect { client.capable?(type: "app", id: "123", capability: "view_metrics") }
        .to(raise_error(Pliny::Errors::Unauthorized))
    end

    it "throws forbidden on a 403 response" do
      stub_heroku_api_request(:put, "#{client.uri}/users/~/capabilities")
        .to_return(status: 403, body: "", headers: {})

      expect { client.capable?(type: "app", id: "123", capability: "view_metrics") }
        .to(raise_error(Pliny::Errors::Forbidden))
    end
  end
end
