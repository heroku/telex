require_relative './user_finder'

module Mediators::Messages
  class AppUserFinder < UserFinder
    private
    def get_notifiables
      if app_info.nil?
        self.users_details = [ ]
        return
      end

      self.users_details = (owners + collabs).uniq {|u| u[:email] }.select do |user|
        # This filters out users who have never logged in
        UserUserFinder.run(target_id: user[:hid]).present?
      end
    end

    def app_info
      @app_info ||= heroku_client.app_info(target_id)
    rescue Telex::HerokuClient::NotFound
      Pliny.log(missing_app: true, app_id: target_id)
      Telex::Sample.count "app_not_found"
      nil
    end

    def owners
      owner = extract_user(:owner, app_info.fetch('owner'))
      if team?(owner[:email])
        team_users(owner[:email])
      else
        [ owner ]
      end
    end

    def team?(email)
      email.end_with?('@herokumanager.com') ||
        Config.deployment == 'staging' && email.end_with?('@staging.herokumanager.com')
    end

    def team_users(owner_email)
      team_members_response = heroku_client.team_members(owner_email.split('@').first)
      team_admins = team_members_response.select { |member| member.fetch('role') == 'admin' }
      team_admins.map do |admin|
        extract_user(:owner, admin.fetch('user'))
      end
    rescue Telex::HerokuClient::NotFound
      # Organization is missing
      Pliny.log(missing_team: true, team: owner_email)
      Telex::Sample.count "team_not_found"
      []
    end

    def collabs
      collab_response = heroku_client.app_collaborators(target_id)
      collab_response.map do |row|
        extract_user(:collaborator, row.fetch('user'))
      end.compact
    rescue Telex::HerokuClient::NotFound
      # Between the time we looked up the app in app_info and now, the app
      # has been deleted.
      # Don't bother sampling since this is only a fluke.
      Pliny.log(missing_app_on_collab_lookup: true, app_id: target_id)
      []
    end
  end
end
