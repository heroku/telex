RSpec.describe Endpoints::ProducerAPI::Users do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      use Pliny::Middleware::RescueErrors # so we get status, not exceptions
      run Endpoints::ProducerAPI::Users
    end
  end

  let(:app_id) { SecureRandom.uuid }

  before do
    Pliny::RequestStore.store[:current_producer] = producer
  end

  describe "GET /users" do
    context "with an un-authorized user" do
      let(:producer) { Fabricate(:producer) }

      it "responds 403" do
        get "/apps/#{app_id}/users"
        expect(last_response.status).to eq 403
      end

      it "responds 422 when an invalid id is used" do
        get "/apps/foo/users"
        expect(last_response.status).to eq 422
      end
    end

    context "with an authorized user" do
      let(:producer) { Fabricate(:producer, name: "a-known-producer") }
      let(:user) { Fabricate(:user) }

      before do
        allow(Config).to receive(:users_endpoint_authorized_producers) { [producer.name] }
      end

      it "lists users" do
        expect(Mediators::Messages::AppUserFinder).to receive(:run).with(target_id: app_id) {
          [UserWithRole.new(:admin, user)]
        }
        get "/apps/#{app_id}/users"
        expect(last_response.status).to eq 200
        body = MultiJson.decode(last_response.body)
        expect(body).to eq [{
          "role" => "admin",
          "user" => {
            "email" => user.email,
            "id" => user.id
          }
        }]
      end

      it "responds 422 when an invalid id is used" do
        get "/apps/foo/users"
        expect(last_response.status).to eq 422
      end
    end
  end
end
