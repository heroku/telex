RSpec.describe Mediators::TeamNotifications::Creator do
  before do
    @creator = described_class.new(message: Fabricate(:message), available_team_notification: Fabricate(:available_team_notification))
  end

  it "creates a message" do
    result = nil
    expect { result = @creator.call }.to change(TeamNotification, :count).by(1)
    expect(result).to be_instance_of(TeamNotification)
    expect(Mail::TestMailer.deliveries.count).to be(1)
  end

  it "does not send duplicate messages" do
    expect {
      @creator.call
      @creator.call
    }.to change(TeamNotification, :count).by(1)

    expect(Mail::TestMailer.deliveries.count).to be(1)
  end

  it "removes the TeamNotification object on message send failures" do
    allow(Telex::Emailer).to receive(:new) { raise Telex::Emailer::DeliveryError }
    expect { @creator.call }.to raise_error Telex::Emailer::DeliveryError
    expect(Mail::TestMailer.deliveries.count).to be(0)
    expect(TeamNotification.count).to be(0)
  end
end
