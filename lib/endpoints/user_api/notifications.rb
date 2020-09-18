module Endpoints
  class UserAPI::Notifications < Base
    namespace "/notifications" do
      before do
        content_type :json, charset: 'utf-8'
      end

      get do
        redis_retry do
          notes = Mediators::Notifications::Lister.run(user: current_user)
          respond_json(notes)
        end
      end

      patch '/mark-all-as-read' do
        redis_retry do
          updated = Mediators::Notifications::ReadAll.run(user: current_user)
          encode({updated: updated})
        end
      end

      patch '/:id' do |id|
        redis_retry do
          note = Mediators::Notifications::ReadStatusUpdater.run(notification: get_note(id), read_status: get_status)
          respond_json(note)
        end
      end

      get '/unread-count' do
        redis_retry do
          unread_count = Mediators::Notifications::UnreadCounter.run(user: current_user)
          encode({unread_count: unread_count})
        end
      end

      get '/:id/read.png' do |id|
        note = ::Notification[id: id]
        raise Pliny::Errors::NotFound unless note
        Mediators::Notifications::ReadStatusUpdater.run(notification: note, read_status: true)

        send_file './lib/templates/read.png'
      end
    end

    private

    def respond_json(note_or_notes)
      sz = Serializers::UserAPI::NotificationSerializer.new(:default)
      encode(sz.serialize(note_or_notes))
    end

    def current_user
      Pliny::RequestStore.store.fetch(:current_user)
    end

    def get_note(id)
      raise Pliny::Errors::UnprocessableEntity unless id =~ Pliny::Middleware::RequestID::UUID_PATTERN
      note = ::Notification[id: id, user_id: current_user.id]
      raise Pliny::Errors::NotFound unless note
      note
    end

    def get_status
      data.fetch('read')
    rescue KeyError
      raise Pliny::Errors::UnprocessableEntity
    end

  end
end
