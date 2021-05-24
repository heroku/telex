RSpec.describe Mediators::Followups::Notifier do
  include HerokuAPIMock

  before do
    @user1, @user2 = fabricate_heroku_user, fabricate_heroku_user
    @note1, @note2 = [@user1, @user2].map { |u| Fabricate(:notification, user: u) }
    @heroku_app = create_heroku_app(owner: @user1, collaborators: [@user1, @user2])
    @message = Fabricate(:message,
      title: Faker::Company.bs,
      notifications: [@note1, @note2],
      target_type: "app",
      target_id: @heroku_app.id)
    @followup = Fabricate(:followup, body: Faker::Company.bs, message: @message)
    @notifier = described_class.new(followup: @followup)
  end

  it "uses the user finder update the users in case their emails have changed" do
    expect(Mediators::Messages::UserUserFinder).to receive(:run).with(target_id: @user1.heroku_id)
    expect(Mediators::Messages::UserUserFinder).to receive(:run).with(target_id: @user2.heroku_id)

    expect(Jobs::SendNotificationEmail).to receive(:perform_async).with(@note1.id, @followup.id)
    expect(Jobs::SendNotificationEmail).to receive(:perform_async).with(@note2.id, @followup.id)

    @notifier.call
  end

  it "emails the users with the new followup" do
    Sidekiq::Testing.inline! do
      @notifier.call
      ds = Mail::TestMailer.deliveries

      expect(ds.size).to eq(2)
      expect(ds.map(&:to).flatten.sort).to eq([@user1, @user2].map(&:email).sort)
      expect(ds.map(&:subject).uniq).to eq([@message.title])
      expect(ds.map(&:in_reply_to).uniq.sort).to eq(["#{@note1.id}@notifications.heroku.com", "#{@note2.id}@notifications.heroku.com"].sort)
    end
  end

  describe "when app belongs to a team" do
    it "notifies admins" do
      admin = fabricate_heroku_user
      team = create_heroku_team(admins: [admin])
      user1, user2 = fabricate_heroku_user, fabricate_heroku_user
      heroku_app = create_heroku_app(owner: admin, collaborators: [user1, user2])

      notes = [admin, user1, user2].map { |u| Fabricate(:notification, user: u) }
      message = Fabricate(:message,
        title: Faker::Company.bs,
        notifications: notes,
        target_type: "app",
        target_id: heroku_app.id)
      followup = Fabricate(:followup, body: Faker::Company.bs, message: message)

      Sidekiq::Testing.inline! do
        described_class.new(followup: followup).call
        ds = Mail::TestMailer.deliveries

        expect(ds.size).to eq(3)
        expect(ds.map(&:to).flatten.sort).to eq([admin, user1, user2].map(&:email).sort)
        expect(ds.map(&:subject).uniq).to eq([message.title])
        expect(ds.map(&:in_reply_to).uniq.sort).to eq(notes.map { |note| "#{note.id}@notifications.heroku.com" }.sort)
      end
    end
  end

  it "does not notify users that have been removed as collabs" do
    update_app_collaborators(@heroku_app, collaborators: [@user1])

    Sidekiq::Testing.inline! do
      described_class.new(followup: @followup).call

      ds = Mail::TestMailer.deliveries
      expect(ds.size).to eq(1)
      expect(ds.map(&:to).flatten.sort).to eq([@user1].map(&:email).sort)
      expect(ds.map(&:subject).uniq).to eq([@message.title])
      expect(ds.map(&:in_reply_to).uniq.sort).to eq(["#{@note1.id}@notifications.heroku.com"])
    end
  end

  describe "when all existing collabs who were notified have been removed" do
    it "notifies all new collabs" do
      users = [fabricate_heroku_user, fabricate_heroku_user]
      heroku_app = create_heroku_app(owner: users.first, collaborators: users)
      notes = users.map do |u|
        Fabricate(:notification, user: u)
      end
      message = Fabricate(:message,
        title: Faker::Company.bs,
        notifications: notes,
        target_type: "app",
        target_id: heroku_app.id)
      followup = Fabricate(:followup, body: Faker::Company.bs, message: message)

      user3 = fabricate_heroku_user
      update_app_collaborators(heroku_app, collaborators: [user3], owner: user3)

      Sidekiq::Testing.inline! do
        described_class.new(followup: followup).call

        ds = Mail::TestMailer.deliveries
        expect(ds.map(&:to).flatten.sort).to eq([user3].map(&:email).sort)
        expect(ds.map(&:in_reply_to)).not_to include(*notes.map { |n| "#{n.id}@notifications.heroku.com" })
      end
    end
  end

  private

  def fabricate_heroku_user
    huser = create_heroku_user
    Fabricate(:user, email: huser.email, heroku_id: huser.heroku_id)
  end
end
