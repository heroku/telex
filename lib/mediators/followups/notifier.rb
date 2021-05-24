module Mediators::Followups
  class Notifier < Mediators::Base
    attr_accessor :followup, :message, :notifications
    def initialize(followup:)
      self.followup = followup
      self.notifications = Mediators::Followups::NotificationUpdater.run(
        followup: followup
      )
    end

    def call
      update_users
      notify_users
    end

    private

    def update_users
      notifications.each do |note|
        Mediators::Messages::UserUserFinder.run(target_id: note.user.heroku_id)
      end
    end

    def notify_users
      notifications.each do |note|
        Jobs::SendNotificationEmail.perform_async(note.id, followup.id)
      end
    end
  end
end
