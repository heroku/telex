class AvailableTeamNotification < Sequel::Model
  plugin :timestamps
  plugin :validation_helpers

  def validate
    super
    validates_unique %i[team_manager_email team_notification_email]
  end
end
