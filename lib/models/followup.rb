class Followup < Sequel::Model
  many_to_one :message

  plugin :timestamps
  plugin :validation_helpers

  def validate
    super
    validates_presence %i(message_id body)
  end
end
