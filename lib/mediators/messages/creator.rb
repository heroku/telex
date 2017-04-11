module Mediators::Messages
  class Creator < Mediators::Base

    APP = "{{app}}"

    def initialize(producer:, title:, body:, action_label:, action_url:, target_type:, target_id:)
      @args = {
        producer_id: producer.id,
        title: title,
        body: body,
        action_label: action_label,
        action_url: action_url,
        target_type: target_type,
        target_id: target_id
      }
    end

    def call
      replace_app_info

      Pliny.log(@args.merge(messages_creator: true, telex: true))
      Jobs::MessagePlex.perform_async(msg.id, skip_email?(msg))
      Telex::Sample.count "messages"
      msg
    end

    private
    def msg
      @msg ||= Message.new(@args)
    end

    def heroku_client
      @heroku_client ||= Telex::HerokuClient.new
    end

    def app_info
      @app_info ||= heroku_client.app_info(msg.target_id, base_headers_only: false)
    end

    def replace_app_info
      if msg.target_type == Message::APP && (msg.title.include?(APP) || msg.body.include?(APP))
        msg[:title] = msg[:title].gsub(APP, app_info.fetch("name"))
        msg[:body] = msg[:body].gsub(APP, app_info.fetch("name"))
      end
      msg.save
    end

    def skip_email?(msg)
      case msg.target_type
      when Message::APP
        !!app_info["name"].match(/^direwolf-/)
      else
        false
      end
    end
  end
end
