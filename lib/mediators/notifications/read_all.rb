module Mediators::Notifications
  class ReadAll < Mediators::Base

    attr_reader :user
    def initialize(user:)
      @user = user
    end

    def call
      notifications.update(read_at: Time.now)
    end

    def notifications
      ::Notification
        .where(user: user)
        .where(read_at: nil)
        .where(Sequel.lit("notifications.created_at > now() - '1 month'::interval"))
    end

  end
end
