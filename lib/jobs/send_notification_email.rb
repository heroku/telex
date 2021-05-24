module Jobs
  class SendNotificationEmail
    include Sidekiq::Worker

    sidekiq_options retry: 10

    # The default retry is exponential
    sidekiq_retry_in do |count|
      200 * (count + 1) # (i.e. 200, 400, 600, 800... seconds)
    end

    def perform(notification_id, followup_id)
      note = Notification[id: notification_id]
      user = note.user
      followup = Followup[id: followup_id]
      message = followup.message

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
