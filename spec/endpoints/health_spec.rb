RSpec.describe Endpoints::Health do
  include Rack::Test::Methods

  describe "GET /" do
    before do
      stub_heroku_api
    end

    it "renders a 200 when all is good" do
      get "/"
      expect(last_response.status).to eq(200)
    end

    it "renders a 503 on database errors" do
      allow(User.db).to receive(:execute) { raise Sequel::DatabaseError }
      get "/"
      expect(last_response.status).to eq(503)
    end

    it "renders a 503 when the API key is invalid" do
      stub_heroku_api do
        get("/*") { 403 }
      end
      get "/"
      expect(last_response.status).to eq(503)
    end

    it "renders a 200 when we're having trouble communicating with API" do
      stub_heroku_api do
        get("/*") { 503 }
      end
      get "/"
      expect(last_response.status).to eq(200)
    end
  end
end
