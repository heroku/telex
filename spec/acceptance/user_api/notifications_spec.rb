RSpec.describe Endpoints::UserAPI::Notifications do
  include HerokuAPIMock
  include Committee::Test::Methods
  include Rack::Test::Methods

  def app
    Routes
  end

  def schema_path
    "./docs/user/schema.json"
  end

  def login(api_key)
    authorize("", api_key)
  end

  describe "GET /user/notifications" do
    context "with bad creds" do
      it "returns a 401" do
        do_get
        expect(last_response.status).to eq(401)
      end
    end

    context "with good creds" do
      let(:heroku_user) { create_heroku_user }

      before do
        login(heroku_user.api_key)
      end

      it "returns a 200" do
        do_get
        expect(last_response.status).to eq(200)
      end

      it "with no notifications, returns an empty json array" do
        do_get
        expect(MultiJson.decode(last_response.body)).to eq([])
      end

      it "returns a 500 when redis is unavailable" do
        allow(Mediators::Notifications::Lister)
          .to receive(:run).with(anything).and_raise(Redis::CannotConnectError)

        do_get
        expect(last_response.status).to eq(500)
      end
    end

    def do_get
      get "/user/notifications"
    end
  end

  describe "GET /user/notifications/unread-count" do
    context "with good creds" do
      let(:heroku_user) { create_heroku_user }
      let(:user) { Fabricate(:user, heroku_id: heroku_user.heroku_id, email: heroku_user.email) }

      before do
        login(heroku_user.api_key)
      end

      context "with unread notifications for the user" do
        before do
          Fabricate(:notification, user: user)
        end

        it "returns the correct unread count" do
          do_get
          body = JSON.parse(last_response.body)
          expect(last_response.status).to eq(200)
          expect(body["unread_count"]).to eq(1)
        end
      end

      context "with unread notifications for another user" do
        let(:another_heroku_user) { create_heroku_user }
        let(:another_user) { Fabricate(:user, heroku_id: another_heroku_user.heroku_id, email: another_heroku_user.email) }

        before do
          Fabricate(:notification, user: user)
          Fabricate(:notification, user: another_user)
        end

        it "does not include other users' unread messages in unread count" do
          do_get
          body = JSON.parse(last_response.body)
          expect(last_response.status).to eq(200)
          expect(body["unread_count"]).to eq(1)
        end
      end

      context "with no notifications" do
        it "returns 0 for the unread count" do
          do_get
          body = JSON.parse(last_response.body)
          expect(last_response.status).to eq(200)
          expect(body["unread_count"]).to eq(0)
        end
      end
    end

    def do_get
      get "/user/notifications/unread-count"
    end
  end

  describe "PATCH /user/notifications/:id" do
    let(:notification) { Fabricate(:notification, user: user) }
    let(:user) { Fabricate(:user, heroku_id: heroku_user.heroku_id, email: heroku_user.email) }
    let(:heroku_user) { create_heroku_user }

    context "with bad creds" do
      it "returns a 401" do
        do_patch(id: notification.id)
        expect(last_response.status).to eq(401)
      end
    end

    context "with good creds" do
      before do
        login(heroku_user.api_key)
      end

      specify "when redis is down" do
        allow(Mediators::Notifications::ReadStatusUpdater).to receive(:run).and_raise(Redis::CannotConnectError)
        do_patch(id: notification.id)
        expect(last_response.status).to eq(500)
      end

      it "returns a 404 if the notification isn't there" do
        do_patch(id: SecureRandom.uuid)
        expect(last_response.status).to eq(404)
      end

      it "returns a 404 if the notification belongs to someone else" do
        other_note = Fabricate(:notification)
        do_patch(id: other_note.id)
        expect(last_response.status).to eq(404)
      end

      it "returns a 422 if the id is malformed" do
        do_patch(id: "notauuid")
        expect(last_response.status).to eq(422)
      end

      it "returns a 200 when everything checks out" do
        do_patch(id: notification.id)
        expect(last_response.status).to eq(200)
      end

      it "returns a 500 when redis is unavailable" do
        allow(Mediators::Notifications::ReadStatusUpdater)
          .to(receive(:run).with(anything).and_raise(Redis::CannotConnectError))

        do_patch(id: notification.id)
        expect(last_response.status).to eq(500)
      end
    end

    def do_patch(id:, body: {read: true})
      patch "/user/notifications/#{id}", MultiJson.encode(body)
    end
  end

  describe "GET /user/notifications/:id/read.png" do
    let(:notification) { Fabricate(:notification) }

    it "returns a 200 for vaild notifications even without auth" do
      get "/user/notifications/#{notification.id}/read.png"
      expect(last_response.status).to eq(200)
    end

    it "returns a 404 for invalid notifications" do
      get "/user/notifications/#{SecureRandom.uuid}/read.png"
      expect(last_response.status).to eq(404)
    end
  end
end
