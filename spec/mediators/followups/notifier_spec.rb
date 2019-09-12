RSpec.describe Mediators::Followups::Notifier do
  before do
    allow(Mediators::Messages::UserUserFinder).to receive(:run)

    @user1, @user2 = 2.times.map { double("user", heroku_id: SecureRandom.uuid, email: Faker::Internet.email) }
    @note1, @note2 = [@user1, @user2].map { |u| double("notification", id: SecureRandom.uuid, user: u) }
    @message = double("message", title: Faker::Company.bs, id: SecureRandom.uuid, notifications: [@note1, @note2])
    @followup = double("followup", body: Faker::Company.bs, message: @message)
    @notifier = described_class.new(followup: @followup)
  end

  it "uses the user finder update the users in case their emails have changed" do
    expect(Mediators::Messages::UserUserFinder).to receive(:run).with(target_id: @user1.heroku_id)
    expect(Mediators::Messages::UserUserFinder).to receive(:run).with(target_id: @user2.heroku_id)

    @notifier.call
  end

  it "emails the users with the new followup" do
    @notifier.call
    ds = Mail::TestMailer.deliveries

    expect(ds.size).to eq(2)
    expect(ds.map(&:to).flatten.sort).to eq([@user1, @user2].map(&:email).sort)
    expect(ds.map(&:subject).uniq).to eq([@message.title])
    expect(ds.map(&:in_reply_to).uniq.sort).to eq(["#{@note1.id}@notifications.heroku.com", "#{@note2.id}@notifications.heroku.com"].sort)
  end
end
