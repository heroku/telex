class Recipient < Sequel::Model
  VERIFICATION_TOKEN_TTL = 7200

  EMAIL = /@/
  TOKEN = %r(%{token})
  ID = %r(%{id})

  plugin :timestamps
  plugin :validation_helpers

  def self.find_active_by_app_id(app_id:)
    self.where(app_id: app_id, active: true, verified: true)
  end

  def self.find_by_id_and_verification_token(id:, verification_token:)
    return unless recipient = self[id]
    return unless recipient.verification_token == verification_token
    return if recipient.verification_token_expired?

    return recipient
  end

  def validate
    super
    validates_presence %i(app_id callback_url email)
    validates_format EMAIL, :email
    validates_format URI.regexp, :callback_url
    validates_format TOKEN, :callback_url
    validates_format ID, :callback_url
  end

  def verification_token_expired?
    (Time.now.utc - verification_sent_at) > VERIFICATION_TOKEN_TTL
  end

  def verification_url
    callback_url % { id: id, token: verification_token }
  end
end
