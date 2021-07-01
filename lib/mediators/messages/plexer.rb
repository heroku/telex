module Mediators::Messages
  class Plexer < Mediators::Base
    attr_accessor :user_finder, :message, :users_with_role
    private :users_with_role=, :message=

    def initialize(message:)
      self.message = message
      self.users_with_role = []
      self.user_finder = Mediators::Messages::UserFinder.from_message(message)
    end

    def call
      get_users
      create_notifications
    end

    private

    def get_users
      self.users_with_role = user_finder.call
    end

    def create_notifications
      users_with_role.map(&:user).uniq { |u| u.id }.each do |user|
        Mediators::Notifications::Creator.run(message: message, notifiable: user)
      end

      # We want to notify Slack Channels on team notifications so on-call people can be aware of events happening.
      available_notification = get_available_notification
      if available_notification.present?
        Mediators::TeamNotifications::Creator.run(message: message, available_team_notification: available_notification)
      end
    end

    def get_available_notification
      return nil if message.target_type != Message::APP || app_info.nil?

      # As message.target_type == Message::APP, we can fetch info such as app owner email through app_info.
      owner_email = app_info.fetch("owner").fetch("email")
      AvailableTeamNotification.find(team_manager_email: owner_email)
    end

    def app_info
      @app_info ||= heroku_client.app_info(message.target_id)
    rescue Telex::HerokuClient::NotFound
      Pliny.log(missing_app: true, app_id: message.target_id)
      Telex::Sample.count "app_not_found"
      nil
    end

    def heroku_client
      Telex::HerokuClient.new
    end
  end
end
