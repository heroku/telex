module Mediators::Messages
  class Cleanup < Mediators::Base
    def initialize(options=nil)
      # required by Mediator api
    end

    def call
      db = Sequel::Model.db
      db.transaction do
        # This takes a long time, so up the timeout for just this transaction:
        db["SET LOCAL statement_timeout = '15min'"].all
        db["DELETE FROM followups
              USING messages
              WHERE messages.id=followups.message_id
                AND messages.created_at < now()-'3 months'::interval"].all
        db["DELETE FROM notifications
              USING messages
              WHERE messages.id=notifications.message_id
                AND messages.created_at < now()-'3 months'::interval"].all
        db["DELETE FROM messages
              WHERE messages.created_at < now()-'3 months'::interval"].all
      end
    end
  end
end
