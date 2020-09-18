RSpec.describe Endpoints::UserAPI::Notifications do
  include Rack::Test::Methods

  before do
    @user = Fabricate(:user)
    Pliny::RequestStore.store[:current_user] = @user
  end

  describe "GET /user/notifications" do
    it "succeeds" do
      get "/notifications"
      expect(last_response.status).to eq(200)
    end
  end

  describe "PATCH /user/notifications/mark-all-as-read" do
    it "marks all as read" do
      unread = Fabricate.times(4, :notification, user: @user, read_at: nil)
      patch "/notifications/mark-all-as-read"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(MultiJson.dump(updated: unread.count))
      unread.each do |note|
        note.reload
        expect(note.read_at).to_not be_nil
      end
    end
  end

  describe "PATCH /user/notifications" do
    it "can set read to now" do
      note = Fabricate(:notification, user: @user, read_at: nil)
      patch "/notifications/#{note.id}", MultiJson.dump({read: true})
      expect(last_response.status).to eq(200)
      note.reload
      expect(note.read_at).to_not be_nil
    end

    it "can set read to nil" do
      note = Fabricate(:notification, user: @user, read_at: Time.now)
      patch "/notifications/#{note.id}", MultiJson.dump({read: false})
      expect(last_response.status).to eq(200)
      note.reload
      expect(note.read_at).to be_nil
    end
  end

  describe "GET /user/notifications/:id/read.png" do
    before do
      Pliny::RequestStore.store.delete(:current_user)
    end

    it "can set read to now without a user" do
      note = Fabricate(:notification, user: @user, read_at: nil)
      get "/notifications/#{note.id}/read.png"
      expect(last_response.status).to eq(200)
      note.reload
      expect(note.read_at).to_not be_nil
    end
  end
end
