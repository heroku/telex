module Mediators::Messages
  class UserFinder < Mediators::Base
    attr_accessor :target_id

    def self.from_message(message)
      type = message.target_type
      case type
      when Message::USER
        UserUserFinder.new(target_id: message.target_id)
      when Message::APP, Message::DASHBOARD
        AppUserFinder.new(target_id: message.target_id)
      when Message::EMAIL
        EmailUserFinder.new(target_id: message.target_id)
      else
        raise "unknown message type: #{type}"
      end
    end

    def initialize(target_id:)
      self.target_id = target_id
    end

    def call
      get_notifiables
      update_or_create_all_users
    end

    private
    attr_accessor :users_details

    def get_notifiables  ; raise NotImplementedError end

    def heroku_client
      Telex::HerokuClient.new
    end

    def update_or_create_all_users
      users_details.map do |details|
        user = update_or_create_user(hid: details[:hid], email: details[:email])
        role = details[:role]
        UserWithRole.new(role, user)
      end
    end

    def update_or_create_user(hid:, email:)
      user = User[heroku_id: hid]
      if user.nil?
        user = User.create(heroku_id: hid, email: email)
      end
      user.email = email
      user.save_changes
      user
    end

    def extract_user(role, response)
      { role: role,
        email: response.fetch('email'),
        hid: response.fetch('id')
      }
    end
  end
end
