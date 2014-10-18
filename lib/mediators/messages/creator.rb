module Mediators::Messages
  class Creator < Mediators::Base
    def initialize(producer:, title:, body:, target_type:, target_id:)
      @message = Message.new(
                   producer_id: producer.id,
                   title: title,
                   body: body,
                   target_type: target_type,
                   target_id: target_id)
    end

    def call
      @message.save
      Jobs::MessagePlex.perform_async(@message.id)
      @message
    end
  end
end
