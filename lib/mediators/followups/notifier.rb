module Mediators::Followups
  class Notifier < Mediators::Base
    attr_accessor :followup, :message, :users
    def initialize(followup: followup)
      self.followup = followup
      self.message = followup.message
      self.users = message.users
    end

    def call
      update_users
      notify_users
    end

    private

    def update_users
      users.each do |user|
        Mediators::Messages::UserUserFinder.run(target_id: user.heroku_id)
      end
    end

    def notify_users
      users.each do |user|
        mail = Mail.new
        mail.to          = user.email
        mail.from        = 'Heroku <bot@heroku.com>'
        mail.in_reply_to = "<#{message.id}@notifications.heroku.com>"
        mail.subject     = message.title
        mail.body        = followup.body

        mail.deliver!
      end
    end
  end
end
