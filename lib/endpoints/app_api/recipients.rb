require_relative "../../mediators/recipients/errors"

module Endpoints
  class AppAPI::Recipients < Base
    namespace "/:app_id" do
      before do
        authorized!
        content_type(:json)

        @app_info = get_app_info
      end

      get "/recipients" do
        recipients = Mediators::Recipients::Lister.run(app_info: @app_info)
        respond_json(recipients)
      end

      post "/recipients" do
        redis_retry do
          recipient = Mediators::Recipients::Creator.run(
            app_info: @app_info,
            email: data.fetch("email", ""),
            template: data.fetch("template", "")
          )
          status 201
          respond_json(recipient)
        end
      end

      put "/recipients/:id/verify" do
        Mediators::Recipients::Verifier.run(
          recipient: get_recipient,
          token: data.fetch("token", "")
        )
        status 204
      end

      patch "/recipients/:id" do
        recipient = Mediators::Recipients::Updater.run(
          app_info: @app_info,
          recipient: get_recipient,
          active: data.fetch("active", false),
          template: data.fetch("template", "")
        )
        respond_json(recipient)
      end

      delete "/recipients/:id" do
        Mediators::Recipients::Deleter.run(
          recipient: get_recipient
        )
        status 204
      end

      private

      def authorized!
        halt 403 unless authorized?
      end

      def authorized?
        heroku_client.capable?(id: params[:app_id], type: "app", capability: "manage_alerts")
      end

      def heroku_client
        Pliny::RequestStore.store.fetch(:heroku_client)
      end

      def respond_json(recipient_or_recipients)
        sz = Serializers::AppAPI::RecipientSerializer.new(:default)
        encode(sz.serialize(recipient_or_recipients))
      end

      def get_recipient
        raise Pliny::Errors::UnprocessableEntity unless Pliny::Middleware::RequestID::UUID_PATTERN.match?(params[:app_id])
        raise Pliny::Errors::UnprocessableEntity unless Pliny::Middleware::RequestID::UUID_PATTERN.match?((params[:id]))

        Recipient[app_id: params[:app_id], id: params[:id], deleted_at: nil] || raise(Pliny::Errors::NotFound)
      end

      def get_app_info
        heroku_client.app_info(params[:app_id], base_headers_only: true)
      end
    end
  end
end
