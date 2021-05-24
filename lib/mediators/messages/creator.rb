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
      Message.new(@args).tap do |msg|
        if msg.target_type == Message::APP && (msg.title.include?(APP) || msg.body.include?(APP))
          app_info = heroku_client.app_info(msg.target_id, base_headers_only: false)
          msg[:title] = msg[:title].gsub(APP, app_info.fetch("name"))
          msg[:body] = msg[:body].gsub(APP, app_info.fetch("name"))
        end
        msg.save
        Pliny.log(@args.merge(messages_creator: true, telex: true))
        Jobs::MessagePlex.perform_async(msg.id)
        Telex::Sample.count "messages"
      end
    end

    private

    def heroku_client
      @heroku_client ||= Telex::HerokuClient.new
    end
  end
end
