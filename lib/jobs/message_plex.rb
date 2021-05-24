module Jobs
  class MessagePlex
    include Sidekiq::Worker

    sidekiq_options retry: 10

    # The default retry is exponential
    sidekiq_retry_in do |count|
      200 * (count + 1) # (i.e. 200, 400, 600, 800... seconds)
    end

    def perform(message_id)
      message = Message[id: message_id]
      Mediators::Messages::Plexer.run(message: message)
    end
  end
end
