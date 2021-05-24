module Endpoints
  class ProducerAPI::Messages < Base
    namespace "/messages" do
      before do
        content_type :json, charset: "utf-8"
      end

      post do
        redis_retry do
          message = Mediators::Messages::Creator.run(
            producer: current_producer,
            title: data["title"],
            body: data["body"],
            action_label: data["action"] && data["action"]["label"],
            action_url: data["action"] && data["action"]["url"],
            target_type: data["target"] && data["target"]["type"],
            target_id: data["target"] && data["target"]["id"]
          )

          status 201
          MultiJson.encode({id: message.id})
        rescue
          raise Pliny::Errors::UnprocessableEntity
        end
      end

      post "/:message_id/followups" do
        redis_retry do
          message = Message[id: params["message_id"]]
          raise Pliny::Errors::NotFound unless message

          followup = Mediators::Followups::Creator.run(
            message: message,
            body: data["body"]
          )

          status 201
          MultiJson.encode({id: followup.id})
        rescue Pliny::Errors::NotFound => e
          raise e
        rescue
          raise Pliny::Errors::UnprocessableEntity
        end
      end
    end

    private

    def current_producer
      Pliny::RequestStore.store.fetch(:current_producer)
    end
  end
end
