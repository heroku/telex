module Mediators::Recipients
  class Updater < Mediators::Base
    attr_reader :app_info, :recipient, :active, :title, :body

    def initialize(app_info:, recipient:, template: nil, active: false)
      @app_info = app_info
      @recipient = recipient
      @active = active

      if template
        @title, @body = TemplateFinder.run(template: template)
      end
    end

    def call
      if regenerate_token?
        Limiter.run(app_info: app_info, recipient: recipient)
      end

      recipient.active = active
      recipient.set(maybe_regenerate_token(title: title, body: body))
      recipient.save

      if regenerate_token?
        Emailer.run(app_info: app_info, recipient: recipient, title: title, body: body)
      end

      recipient
    end

    def maybe_regenerate_token(title:, body:)
      return {} unless regenerate_token?

      {verification_token: Recipient.generate_token, verification_sent_at: Time.now.utc}
    end

    def regenerate_token?
      !title.to_s.empty? && !body.to_s.empty?
    end
  end
end
