require_relative "./user_finder"

module Mediators::Messages
  class UserUserFinder < UserFinder
    private

    def get_notifiables
      user_response = heroku_client.account_info(user_uuid: target_id)

      id = user_response.fetch("id")

      if id != target_id
        raise "Mismatching ids, asked for #{target_id}, got #{id}"
      end

      self.users_details = if user_response.fetch("last_login")
        [extract_user(:self, user_response)]
      else
        []
      end
    rescue Telex::HerokuClient::NotFound
      self.users_details = []
      Telex::Sample.count "user_not_found"
    end
  end
end
