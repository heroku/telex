module Mediators::Messages
  class Plexer < Mediators::Base
    attr_accessor :user_finder, :message, :users_with_role, :skip_email
    private :users_with_role=, :message=, :skip_email=

    def initialize(message:, skip_email:)
      self.message = message
      self.skip_email = skip_email
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
        Mediators::Notifications::Creator.run(
          message: message,
          notifiable: user,
          skip_email: skip_email
        )
      end
    end
  end
end
