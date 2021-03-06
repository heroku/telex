RSpec.describe Mediators::Followups::NotificationUpdater do
  include HerokuAPIMock

  before do
    @user1, @user2 = create_heroku_user, create_heroku_user
    @note1, @note2 = [@user1, @user2].map { |u| double("notification", id: SecureRandom.uuid, user: u) }
    @heroku_app = create_heroku_app(owner: @user1, collaborators: [@user1, @user2])
  end

  it "returns notifications from collabs who received the original message" do
    message = double("message",
      title: Faker::Company.bs,
      id: SecureRandom.uuid,
      notifications: [@note1, @note2],
      target_type: "app",
      target_id: @heroku_app.id)
    followup = double("followup", body: Faker::Company.bs, message: message)
    notifications = described_class.run(followup: followup)

    expect(notifications).to contain_exactly(@note1, @note2)
  end

  it "creates and returns notifications for all collabs if none received the original message" do
    owner = Fabricate(:user, email: @user1.email, heroku_id: @user1.heroku_id)
    note = Fabricate(:notification, user: owner)
    message = Fabricate(:message,
      title: Faker::Company.bs,
      notifications: [note],
      target_type: "app",
      target_id: @heroku_app.id)

    followup = double("followup", body: Faker::Company.bs, message: message)
    user3, user4 = 2.times.map do
      huser = create_heroku_user
      Fabricate(:user, email: huser.email, heroku_id: huser.heroku_id)
    end

    update_app_collaborators(@heroku_app, owner: user3, collaborators: [user3, user4])
    notifications = described_class.run(followup: followup)
    expected = notifications.map(&:user)

    expect(expected).to contain_exactly(user3, user4)
  end
end
