module Mediators::Recipients
  class Limiter < Mediators::Base
    MAX_PER_APP = 5
    MAX_PER_DAY = 5
    MAX_REFRESH_INTERVAL = 60

    attr_reader :app_info, :max_per_app, :max_per_day, :max_refresh_interval, :recipient

    def initialize(app_info:, recipient: nil, max_per_app: MAX_PER_APP, max_per_day: MAX_PER_DAY, max_refresh_interval: MAX_REFRESH_INTERVAL)
      @app_info = app_info
      @max_per_app = max_per_app
      @max_per_day = max_per_day
      @max_refresh_interval = max_refresh_interval
      @recipient = recipient
    end

    def call
      if Recipient.where(app_id: app_info.fetch("id"), deleted_at: nil).count >= max_per_app
        raise LimitError, "You can only have a maximum of %d recipients per app" % max_per_app
      end

      if created_today.count >= max_per_day
        raise LimitError, "You can only create a maximum of %d recipients per day" % max_per_day
      end

      if recipient && (Time.now.utc - recipient.verification_sent_at) < max_refresh_interval
        raise LimitError, "You can only refresh your token every %d seconds" % max_refresh_interval
      end
    end

    private

    def created_today
      Recipient.where(Sequel.lit("app_id = ? and ? <= created_at and created_at < ?",
        app_info.fetch("id"), today, tomorrow))
    end

    def today
      Time.now.utc.strftime("%Y-%m-%d")
    end

    def tomorrow
      (Time.now.utc + 86400).strftime("%Y-%m-%d")
    end
  end
end
