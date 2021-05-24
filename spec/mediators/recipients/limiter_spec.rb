RSpec.describe Mediators::Recipients::Limiter do
  before do
    @app_info = {
      "id" => SecureRandom.uuid,
      "name" => "brat"
    }
    @limiter = described_class.new(app_info: @app_info,
                                   max_per_day: 1,
                                   max_per_app: 2)
  end

  describe "limits per day" do
    before do
      # pretend we have one created yesterday
      Fabricate(:recipient, app_id: @app_info.fetch("id"), created_at: Time.now.utc - 86400)
    end

    it "does not raise an error when no limit is hit" do
      expect { @limiter.call }.not_to raise_error
    end

    it "raises LimitError with a limit hit" do
      Fabricate(:recipient, app_id: @app_info.fetch("id"))
      expect { @limiter.call }.to raise_error(Mediators::Recipients::LimitError)
    end

    it "takes deletions into account for limits" do
      Fabricate(:recipient, app_id: @app_info.fetch("id"), deleted_at: Time.now)
      expect { @limiter.call }.to raise_error(Mediators::Recipients::LimitError)
    end
  end

  describe "limits per account" do
    before do
      @limiter = described_class.new(app_info: @app_info,
                                     max_per_day: 10,
                                     max_per_app: 2)
    end

    it "does not limit for deleted emails" do
      @limiter.call # no error

      Fabricate(:recipient, app_id: @app_info.fetch("id"), deleted_at: Time.now)
      Fabricate(:recipient, app_id: @app_info.fetch("id"), deleted_at: Time.now)

      @limiter.call # no error still
    end

    it "limits to max_per_app" do
      Fabricate(:recipient, app_id: @app_info.fetch("id"))
      Fabricate(:recipient, app_id: @app_info.fetch("id"))

      expect { @limiter.call }.to raise_error(Mediators::Recipients::LimitError)
    end
  end

  describe "token refresh frequency limits" do
    before do
      recipient = Fabricate(:recipient, app_id: @app_info.fetch("id"))
      @limiter = described_class.new(app_info: @app_info, max_refresh_interval: 0.5, recipient: recipient)
    end

    it "allows you within the refresh interval" do
      expect { @limiter.call }.to raise_error(Mediators::Recipients::LimitError)

      sleep(1)
      @limiter.call # no error after the interval
    end
  end
end
