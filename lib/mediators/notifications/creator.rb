module Mediators::Notifications
  class Creator < Mediators::Base
    def initialize(notifiable:, message:, skip_email:)
      self.notifiable = notifiable
      self.message = message
      self.skip_email = skip_email
    end

    def call
      self.notification = Notification.create(notifiable: notifiable, message_id: message.id)
      # One possibility. Just jotting down notes
      # send_email unless message.target_type == Message::DASHBOARD
      send_email
      notification
    rescue Sequel::ValidationFailed, Sequel::UniqueConstraintViolation
      # Notification already queued, just ignore.
      Pliny.log(duplicate_notificaiton: true, notifiable_id: notifiable.id, notifiable_type: notifiable.class, message_id: message.id)
    rescue => e
      # ^ Typically an email send failure.
      # Remove the notification before we re-raise so the mediator can be run
      # again.
      Notification.find_by_notifiable_and_message(notifiable: notifiable, message: message).delete
      raise e
    end

    private
    attr_accessor :notifiable, :message, :notification, :skip_email

    def send_email
      return if skip_email
      emailer = Telex::Emailer.new(
        email: notifiable.email,
        notification_id: notification.id,
        subject: message.title,
        body: message.body,
        action: message.action,
      )
      emailer.deliver!
    end

  end
end

