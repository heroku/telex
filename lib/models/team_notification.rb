class TeamNotification < Sequel::Model
  many_to_one :message

  plugin :timestamps
  plugin :validation_helpers

  WEB_SERVICES_MANAGER_EMAIL_ADDRESS = Config.web_services_manager_email_address
  NOTIFIABLE_TEAMS = {
    WEB_SERVICES_MANAGER_EMAIL_ADDRESS => Config.web_services_slack_channel_email_address
  }

  def validate
    super
    validates_unique %i[message email]
  end
end
