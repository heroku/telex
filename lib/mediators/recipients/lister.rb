module Mediators::Recipients
  class Lister < Mediators::Base
    attr_reader :app_info

    def initialize(app_info:)
      @app_info = app_info
    end

    def call
      Recipient.where(app_id: app_info.fetch("id"), deleted_at: nil)
    end
  end
end
