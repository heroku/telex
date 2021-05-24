RSpec.describe Mediators::Recipients::Emailer do
  let(:app_info) { {"name" => "myapp"} }
  let(:recipient) { Fabricate(:recipient) }

  it "sends an email given recipient / app_info" do
    emailer = double
    args = {
      email: recipient.email,
      notification_id: Pliny::Middleware::RequestID::UUID_PATTERN,
      subject: "hello myapp",
      body: "myapp #{recipient.verification_token}",
      strip_text: true
    }
    allow(Telex::Emailer).to receive(:new).with(hash_including(args)) { emailer }
    allow(emailer).to receive(:deliver!)

    described_class.run(app_info: app_info, recipient: recipient, title: "hello {{app}}", body: "{{app}} {{token}}")
  end

  it "leaves other var-looking things in the body alone" do
    emailer = double
    args = {
      email: recipient.email,
      notification_id: Pliny::Middleware::RequestID::UUID_PATTERN,
      subject: "hello",
      body: "myapp #{recipient.verification_token} {{yoyo}}",
      strip_text: true
    }
    allow(Telex::Emailer).to receive(:new).with(hash_including(args)) { emailer }
    allow(emailer).to receive(:deliver!)

    described_class.run(app_info: app_info, recipient: recipient, title: "hello", body: "{{app}} {{token}} {{yoyo}}")
  end

  it "raises BadRequest if app/token are missing" do
    bad_bodies = [
      "{{yoyo}}",
      "",
      "{{app}}",
      "{{token}}"
    ]

    bad_bodies.each do |body|
      expect {
        described_class.run(app_info: app_info, recipient: recipient, title: "hello", body: body)
      }.to raise_error(Mediators::Recipients::BadRequest)
    end
  end
end
