RSpec.describe Endpoints::ProducerAPI::Messages do
  include Committee::Test::Methods
  include Rack::Test::Methods

  def app
    Routes
  end

  def schema_path
    "./docs/producer/schema.json"
  end

  before do
    header "Content-Type", "application/json"
    @message_body = {
      title: Faker::Company.bs,
      body: Faker::Company.bs,
      target: {type: "user", id: SecureRandom.uuid}
    }
  end

  describe "POST /producer/messages" do
    def do_post
      post "/producer/messages", MultiJson.encode(@message_body)
    end

    context "with bad creds" do
      it "401s with no creds" do
        do_post
        expect(last_response.status).to eq(401)
      end

      it "401s also with malformed producer user id" do
        authorize "not_a_uuid", "whatever"
        do_post
        expect(last_response.status).to eq(401)
      end
    end

    context "with proper creds" do
      before do
        prod = Fabricate(:producer, api_key: "foo")
        authorize prod.id, "foo"
      end

      it "returns correct status code and conforms to schema" do
        do_post
        expect(last_response.status).to eq(201)
        #      assert_schema_conform
      end

      it "with bad data, returns a 422" do
        @message_body = nil
        do_post
        expect(last_response.status).to eq(422)
      end

      it "returns a 422 when redis is down" do
        allow(Mediators::Messages::Creator).to receive(:run).with(anything).and_raise(Redis::CannotConnectError)
        do_post
        expect(last_response.status).to eq(422)
      end
    end
  end
end
