class TeamNotification < Sequel::Model
  many_to_one :message

  plugin :timestamps
  plugin :validation_helpers

  def validate
    super
    validates_unique %i[message email]
  end
end
