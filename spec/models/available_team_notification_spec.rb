RSpec.describe AvailableTeamNotification do
  let(:team_manager_email) { Fabricate(:user).email }
  let(:team_notification_email) { Fabricate(:user).email }

  it "validates uniqueness of (email,message)" do
    AvailableTeamNotification.create(team_notification_email: team_notification_email, team_manager_email: team_manager_email)
    expect {
      AvailableTeamNotification.create(team_notification_email: team_notification_email, team_manager_email: team_manager_email)
    }.to raise_error(Sequel::ValidationFailed)
  end
end
