module Mediators::Recipients
  class Emailer < Mediators::Base
    attr_reader :app_info, :recipient, :title, :body

    APP = "{{app}}"
    TOKEN = "{{token}}"

    def initialize(app_info:, recipient:, title:, body:)
      @app_info = app_info
      @recipient = recipient
      @title = title.to_s
      @body = body.to_s
    end

    def call
      validate
      send_email
    end

    def validate
      if title.empty?
        raise BadRequest, "`title` is required"
      end

      if !body.include?(APP) || !body.include?(TOKEN)
        raise BadRequest, "`body` should have %s and %s" % [APP, TOKEN]
      end
    end

    private

    def generate_confirmation_email
      Message.new(
        title: title.gsub(APP, app_info.fetch("name")),
        body: body.gsub(APP, app_info.fetch("name")).gsub(TOKEN, recipient.verification_token)
      )
    end

    def send_email
      message = generate_confirmation_email
      emailer = Telex::Emailer.new(
        email: recipient.email,
        notification_id: recipient.id,
        subject: message.title,
        body: message.body,
        action: message.action,
        strip_text: true
      )
      emailer.deliver!
    end
  end
end
