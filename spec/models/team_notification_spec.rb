RSpec.describe TeamNotification do
  let :message do
    Message.create(
      target_type: "app", target_id: SecureRandom.uuid,
      title: "hello", body: "world",
      producer: Producer.create(api_key: SecureRandom.uuid, name: "myservice")
    )
  end

  let(:email) { Fabricate(:user).email }

  it "validates uniqueness of (email,message)" do
    TeamNotification.create(email: email, message: message)
    expect {
      TeamNotification.create(email: email, message: message)
    }.to raise_error(Sequel::ValidationFailed)
  end
end
