class Message < Sequel::Model
  DASHBOARD = "dashboard"
  EMAIL = "email"
  USER = "user"
  APP = "app"

  many_to_many :users, join_table: :notifications
  many_to_one :producer
  one_to_many :notifications
  one_to_many :followup

  plugin :timestamps
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[target_type target_id title body producer_id]
  end

  def action
    return unless action_label && action_url
    {label: action_label, url: action_url}
  end
end
