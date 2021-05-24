module Mediators::Notifications
  class Lister < Mediators::Base
    def initialize(user:)
      @user = user
    end

    def call
      Notification
        .eager_graph(message: :followup)
        .where(user: @user)
        .where(Sequel.lit("notifications.created_at > now() - '1 month'::interval"))
        .order(Sequel.desc(:created_at), Sequel.qualify("followup", "created_at"))
        .all
    end
  end
end
