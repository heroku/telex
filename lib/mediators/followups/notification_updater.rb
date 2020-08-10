module Mediators::Followups
  class NotificationUpdater < Mediators::Base
    attr_accessor :message

    def initialize(followup:)
      self.message = followup.message
    end

    def call
      update_notifications
    end

    private

    # if any collaborators who received the original message are still collabs, send it to just that list minus
    # anyone who was removed as a collab. Otherwise, send it to all current collabs.
    # Sometimes a user may not exist in telex yet, so have to create them.
    def update_notifications
      if original_message_recipient_notifications.any?
        original_message_recipient_notifications
      else
        create_notifications_for_all_collabs
      end
    end

    def original_message_recipient_notifications
      message.notifications.select do |n|
        current_collab_hids.include?(n.user.heroku_id)
      end
    end

    def create_notifications_for_all_collabs
      notifiable_hids = message.notifications.map {|n| n.user.heroku_id }
      new_notifiables = []

      current_collabs.each do |c|
        if !notifiable_hids.include?(c["user"]["id"])
          # not using the notification mediator here because it sends an email,
          # which we also do in this mediator
          user = find_or_create_user(c["user"]["id"], c["user"]["email"])
          new_notifiables << Notification.create(notifiable: user, message_id: message.id)
        end
      end

      new_notifiables
    end

    def find_or_create_user(heroku_id, email)
      User[heroku_id: heroku_id] || User.create(heroku_id: heroku_id, email: email)
    end

    def current_collab_hids
      current_collabs.map {|c| c["user"]["id"] }
    end

    def current_collabs
      @current_collabs ||= Telex::HerokuClient.new.app_collaborators(message.target_id)
    end
  end
end
