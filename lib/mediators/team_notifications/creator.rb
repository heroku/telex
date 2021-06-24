module Mediators::TeamNotifications
  class Creator < Mediators::Base
    def initialize(message:, email:)
      self.message = message
      self.email = email
    end

    def call
      self.team_notification = TeamNotification.create(message_id: message.id, email: email)
      send_email
      team_notification
    rescue Sequel::ValidationFailed, Sequel::UniqueConstraintViolation
      # TeamNotification already queued, just ignore.
      Pliny.log(duplicate_team_notificaiton: true, message_id: message.id, email: email)
    rescue => e
      # ^ Typically an email send failure.
      # Remove team_notification before we re-raise so the mediator can be run
      # again.
      TeamNotification.find_by(message_id: message.id, email: email).delete
      raise e
    end

    private

    attr_accessor :message, :email, :team_notification

    def send_email
      emailer = Telex::Emailer.new(
        email: email,
        subject: message.title,
        body: message.body,
        action: message.action
      )
      emailer.deliver!
    end
  end
end
