require "spec_helper"

describe Endpoints::Producer::Messages do
  include Rack::Test::Methods

  def app
    Endpoints::Producer::Messages  end

  before do
    @producer = Fabricate(:producer)
    Pliny::RequestStore.store[:current_producer] = @producer
  end

  describe "POST /messages" do
    def do_post
      post "/messages", MultiJson.encode(@message_body)
    end

    before do
      @message_body = {
        title: 'Congratulations',
        body: 'You are a winner',
        target: {type: 'user', id: SecureRandom.uuid}
      }
    end

    context 'with good params' do
      it "succeeds" do
        do_post
        expect(last_response.status).to eq(201)
      end

      it 'creates a message' do
        expect(Message.where(producer_id: @producer.id).count).to eq(0)
        do_post
        expect(Message.where(producer_id: @producer.id).count).to eq(1)
      end

      it "returns the message's id" do
        do_post
        response = MultiJson.decode(last_response.body)
        expect( Message[id: response['id']] ).to_not be_nil
      end
    end

    context 'with bad params' do
      before do
        @message_body[:body] = ''
      end

      it "fails" do
        do_post
        expect(last_response.status).to eq(406)
      end
    end

  end

  describe "POST /messages/:id/followups" do
    def do_post
      post "/messages/#{@message.id}/followups", MultiJson.encode(@followup_body)
    end

    before do
      @message = Fabricate(:message, producer_id: @producer.id)
      @followup_body = {
        body: 'You actually are not a winner :(',
      }
    end

    context 'with good params' do
      it "succeeds" do
        do_post
        expect(last_response.status).to eq(201)
      end

      it 'creates a followup' do
        expect(Followup.where(message_id: @message.id).count).to eq(0)
        do_post
        expect(Followup.where(message_id: @message.id).count).to eq(1)
      end

      it "returns the followup's id" do
        do_post
        response = MultiJson.decode(last_response.body)
        expect( Followup[id: response['id']] ).to_not be_nil
      end
    end

    context 'with bad params' do
      it "fails with an empty body" do
        @followup_body[:body] = ''
        do_post
        expect(last_response.status).to eq(406)
      end

      it "fails with a malformed message_id" do
        @message.id = 'whatever'
        do_post
        expect(last_response.status).to eq(406)
      end

      it "fails with a missing message_id" do
        @message.id = SecureRandom.uuid
        do_post
        expect(last_response.status).to eq(406)
      end

      it "fails when the message belongs to a different producer" do
        @message.producer_id = SecureRandom.uuid
        @message.save
        do_post
        expect(last_response.status).to eq(406)
      end
    end

  end
end
