include Mediators::Messages

RSpec.describe Plexer, "#call" do
  include HerokuAPIMock

  let(:client) { Telex::HerokuClient.new }

  before do
    @message = Fabricate(:message, target_type: "app")
    @plexer = Plexer.new(message: @message)
    @uwrs = Array.new(2) { UserWithRole.new(:whatever, Fabricate(:user)) }
  end

  it "uses the user finder to set @users_with_role" do
    stub_non_herokumanager_request
    user_finder = double("user finder")
    @plexer.user_finder = user_finder

    expect(@plexer.users_with_role).to eq([])
    expect(user_finder).to receive(:call).and_return(@uwrs)
    @plexer.call
    expect(@plexer.users_with_role).to eq(@uwrs)
  end

  it "picks the appropriate user finder" do
    allow(@message).to receive(:target_type).and_return("app")
    plexer = Plexer.new(message: @message)
    expect(plexer.user_finder).to be_instance_of(Mediators::Messages::AppUserFinder)
  end

  it "picks the email finder on email" do
    allow(@message).to receive(:target_type).and_return("email")
    plexer = Plexer.new(message: @message)
    expect(plexer.user_finder).to be_instance_of(Mediators::Messages::EmailUserFinder)
  end

  it "creates a Notificaton for each user" do
    stub_non_herokumanager_request
    @plexer.user_finder = double("user finder", call: @uwrs)

    expect(Mediators::Notifications::Creator).to receive(:run).with(
      message: @message, notifiable: @uwrs[0].user
    )
    expect(Mediators::Notifications::Creator).to receive(:run).with(
      message: @message, notifiable: @uwrs[1].user
    )
    @plexer.call
  end

  it "does not create a TeamNotification" do
    stub_non_herokumanager_request
    @plexer.user_finder = double("user finder", call: @uwrs)

    expect(Mediators::TeamNotifications::Creator).not_to receive(:run)

    @plexer.call
  end

  context "when app is owned by Web Services" do
    let(:manager_email) { Faker::Internet.email }
    let(:team_notification_email) { Faker::Internet.email  }
    let(:expected_available_team_notification) { AvailableTeamNotification.find(team_notification_email: team_notification_email) }

    before do
      AvailableTeamNotification.create(team_notification_email: team_notification_email, team_manager_email: manager_email)
      manager_id = SecureRandom.uuid
      stub_team_members_request(manager_email)
      stub_account_request(manager_id)
      stub_owner_request(manager_email, manager_id)
    end

    it "creates a TeamNotification with the correct email address" do
      expect(Mediators::TeamNotifications::Creator).to receive(:run).with(
        message: @message, available_team_notification: expected_available_team_notification
      )

      @plexer.call
    end
  end

  private

  def stub_account_request(manager_id)
    stub_heroku_api_request(:get, "#{client.uri}/account").to_return(status: 200, body: {"id" => manager_id, "last_login" => nil }.to_json)
  end

  def stub_team_members_request(email)
    team = email.split("@").first
    stub_heroku_api_request(:get, "#{client.uri}/teams/#{team}/members").to_return(status: 200, body: [].to_json)
    stub_heroku_api_request(:get, "#{client.uri}/apps/#{@message.target_id}/collaborators").to_return(status: 200, body: [].to_json)
  end

  def stub_non_herokumanager_request
    values = @uwrs.first.user.values
    stub_owner_request(values[:email], values[:id])
  end

  def stub_owner_request(email, id)
    stub_heroku_api_request(:get, "#{client.uri}/apps/#{@message.target_id}")
      .to_return(status: 200, body: {"name"=>"example", "owner"=>{"email"=>email, "id"=>id}}.to_json)
  end
end
