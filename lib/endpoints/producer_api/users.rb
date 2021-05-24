module Endpoints
  class ProducerAPI::Users < Base
    namespace "/apps/:app_id/users" do
      before do
        unless Pliny::Middleware::RequestID::UUID_PATTERN.match?(params[:app_id])
          raise Pliny::Errors::UnprocessableEntity
        end
        authorized!
        content_type :json, charset: "utf-8"
      end

      get do
        users_with_roles = Mediators::Messages::AppUserFinder.run(target_id: params[:app_id])
        respond_json(users_with_roles)
      end

      private

      def authorized!
        halt 403 unless authorized?
      end

      def authorized?
        # for now only allow a known list of producers to access this endpoint
        current_producer &&
          Config.users_endpoint_authorized_producers.include?(current_producer.name)
      end

      def current_producer
        Pliny::RequestStore.store.fetch(:current_producer)
      end

      def respond_json(users)
        sz = Serializers::ProducerAPI::UserWithRoleSerializer.new(:default)
        encode(sz.serialize(users))
      end
    end
  end
end
