require_relative './user_finder'

module Mediators::Messages
  class EmailUserFinder < UserFinder
    private
    def get_notifiables
      self.users_details = Recipient.find_active_by_app_id(app_id: target_id).map do |r|
        extract_user(:self, { "email" => r.email, "id" => r.id })
      end
    end

    def update_or_create_user(hid:, email:)
      Recipient[hid]
    end
  end
end