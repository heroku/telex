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

    # if there exists collaborators who received the original message, send it to them.
    # otherwise, send it to all collabs. Sometimes this user may not exist in telex yet,
    # so we have to create them.
    def update_notifications
      if notifications_for_collabs_that_recieved_original_message.any?
        notifications_for_collabs_that_recieved_original_message
      else
        create_notifications_for_new_collabs
      end
    end

    def notifications_for_collabs_that_recieved_original_message
      message.notifications.select do |n|
        current_collab_hids.include?(n.user.heroku_id)
      end
    end

    def create_notifications_for_new_collabs
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