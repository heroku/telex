RSpec.describe Jobs::SendNotificationEmail, "#perform" do
  it "sends emails with Telex::Emailer" do
    notification = Fabricate(:notification)
    message = Fabricate(:message, notifications: [notification])
    followup = Fabricate(:followup, message: message)

    expect(Telex::Emailer).to receive(:new).with(
      email: notification.user.email,
      in_reply_to: notification.id,
      subject: message.title,
      body: followup.body
    ).and_call_original

    Jobs::SendNotificationEmail.new.perform(notification.id, followup.id)
  end
end
