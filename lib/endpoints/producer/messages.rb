module Endpoints
  class Producer::Messages < Base
    namespace "/messages" do
      before do
        content_type :json, charset: 'utf-8'
      end

      post do
        begin
          message = Mediators::Messages::Creator.run(
            producer: current_producer,
            title:       data['title'],
            body:        data['body'],
            target_type: data['target'] && data['target']['type'],
            target_id:   data['target'] && data['target']['id']
          )

          status 201
          MultiJson.encode({id: message.id})
        rescue
          raise Pliny::Errors::NotAcceptable
        end
      end

      post '/:message_id/followups' do
        begin
          message = Message[id: params['message_id'], producer_id: current_producer.id]
          followup = Mediators::Followups::Creator.run(
            message: message,
            body:    data['body']
          )

         status 201
         MultiJson.encode({id: followup.id})
        rescue
          raise Pliny::Errors::NotAcceptable
        end
      end

    end

    private

    def data
      MultiJson.decode(request.body.read).tap do
        request.body.rewind
      end
    end

    def current_producer
      Pliny::RequestStore.store.fetch(:current_producer)
    end

  end
end
