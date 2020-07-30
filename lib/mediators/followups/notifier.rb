module Mediators::Followups
  class Notifier < Mediators::Base
    attr_accessor :followup, :message, :notifications
    def initialize(followup: )
      self.followup = followup
      self.message = followup.message
      self.notifications = filter_notifications
    end

    def call
      update_users
      notify_users
    end

    private

    def heroku_client
      @client ||= Telex::HerokuClient.new
    end

    def filter_notifications
      current_collabs_ids = heroku_client.app_collaborators(message.target_id).map do |c|
        c["user"]["id"]
      end

      message.notifications.select do |n|
        current_collabs_ids.include?(n.user.heroku_id)
      end
    end

    def update_users
      notifications.each do |note|
        Mediators::Messages::UserUserFinder.run(target_id: note.user.heroku_id)
      end
    end

    def notify_users
      notifications.each do |note|
        user = note.user
        emailer = Telex::Emailer.new(
          email: user.email,
          in_reply_to: note.id,
          subject: message.title,
          body: followup.body
        )
        emailer.deliver!
      end
    end
  end
end
