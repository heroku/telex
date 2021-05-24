module Mediators::Notifications
  class Creator < Mediators::Base
    def initialize(notifiable:, message:)
      self.notifiable = notifiable
      self.message = message
    end

    def call
      self.notification = Notification.create(notifiable: notifiable, message_id: message.id)
      send_email unless message.target_type == Message::DASHBOARD
      notification
    rescue Sequel::ValidationFailed, Sequel::UniqueConstraintViolation
      # Notification already queued, just ignore.
      Pliny.log(duplicate_notificaiton: true, notifiable_id: notifiable.id, notifiable_type: notifiable.class.name, message_id: message.id)
    rescue => e
      # ^ Typically an email send failure.
      # Remove the notification before we re-raise so the mediator can be run
      # again.
      Notification.find_by_notifiable_and_message(notifiable: notifiable, message: message).delete
      raise e
    end

    private

    attr_accessor :notifiable, :message, :notification

    def send_email
      emailer = Telex::Emailer.new(
        email: notifiable.email,
        notification_id: notification.id,
        subject: message.title,
        body: message.body,
        action: message.action
      )
      emailer.deliver!
    end
  end
end
