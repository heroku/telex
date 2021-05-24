RSpec.describe Mediators::Recipients::Creator do
  before do
    @app_info = {
      "id" => SecureRandom.uuid,
      "name" => "brat"
    }
  end

  it "creates a recipient via the named template" do
    Mediators::Recipients::TemplateFinder.setup(template: "alerting", title: "hello", body: "%{app} %{token}") do
      @creator = described_class.new(app_info: @app_info,
                                     email: "foo@bar.com",
                                     template: "alerting")

      allow(Mediators::Recipients::Emailer).to receive(:run).with(
        app_info: @app_info, recipient: kind_of(Recipient),
        template: "alerting"
      )

      result = nil
      expect { result = @creator.call }.to change(Recipient, :count).by(1)
      expect(result).to be_instance_of(Recipient)
    end
  end
end
