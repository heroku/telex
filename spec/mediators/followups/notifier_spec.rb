RSpec.describe Mediators::Followups::Notifier do
include HerokuAPIMock

before do
  @user1, @user2 = create_heroku_user, create_heroku_user
  @note1, @note2 = [@user1, @user2].map { |u| double("notification", id: SecureRandom.uuid, user: u) }
  @heroku_app = create_heroku_app(owner: @user1, collaborators: [@user1, @user2])
  @message = double("message",
    title: Faker::Company.bs,
    id: SecureRandom.uuid,
    notifications: [@note1, @note2],
    target_type: "app",
    target_id: @heroku_app.id)
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

describe "when app belongs to a team" do
  it "notifies admins" do
    admin = create_heroku_user
    team = create_heroku_team(admins: [admin])
    user1, user2 = create_heroku_user, create_heroku_user
    heroku_app = create_heroku_app(owner: admin, collaborators: [user1, user2])

    notes = [admin, user1, user2].map { |u| double("notification", id: SecureRandom.uuid, user: u) }
    message = double("message",
                     title: Faker::Company.bs,
                     id: SecureRandom.uuid,
                     notifications: notes,
                     target_type: "app",
                     target_id: heroku_app.id)
    followup = double("followup", body: Faker::Company.bs, message: message)

    described_class.new(followup: followup).call
    ds = Mail::TestMailer.deliveries

    expect(ds.size).to eq(3)
    expect(ds.map(&:to).flatten.sort).to eq([admin, user1, user2].map(&:email).sort)
    expect(ds.map(&:subject).uniq).to eq([message.title])
    expect(ds.map(&:in_reply_to).uniq.sort).to eq(notes.map { |note| "#{note.id}@notifications.heroku.com" }.sort)
  end
end

it "does not notify users that have been removed as collabs" do
  update_app_collaborators(@heroku_app, collaborators: [@user1])
  described_class.new(followup: @followup).call

  ds = Mail::TestMailer.deliveries
  expect(ds.size).to eq(1)
  expect(ds.map(&:to).flatten.sort).to eq([@user1].map(&:email).sort)
  expect(ds.map(&:subject).uniq).to eq([@message.title])
  expect(ds.map(&:in_reply_to).uniq.sort).to eq(["#{@note1.id}@notifications.heroku.com"])
end

describe "when all existing collabs who were notified have been removed" do
  it "notifies all new collabs" do
    user1, user2 = create_heroku_user, create_heroku_user
    heroku_app = create_heroku_app(owner: user1, collaborators: [user1, user2])
    users = [user1, user2].map do |u|
      Fabricate(:user, email: u.email, heroku_id: u.heroku_id)
    end
    notes = users.map do |u|
      Fabricate(:notification, user: u)
    end
    message = Fabricate(:message,
      title: Faker::Company.bs,
      id: SecureRandom.uuid,
      notifications: notes,
      target_type: "app",
      target_id: heroku_app.id)
    followup = double("followup", body: Faker::Company.bs, message: message)

    user3 = create_heroku_user
    update_app_collaborators(heroku_app, collaborators: [user3], owner: user3)
    described_class.new(followup: followup).call

    ds = Mail::TestMailer.deliveries
    expect(ds.map(&:to).flatten.sort).to eq([user3].map(&:email).sort)
    expect(ds.map(&:in_reply_to)).not_to include(*notes.map { |n| "#{n.id}@notifications.heroku.com" })
  end
end
end
