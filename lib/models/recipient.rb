class Recipient < Sequel::Model
  VERIFICATION_TOKEN_TTL = 7200

  EMAIL = /@/

  plugin :timestamps
  plugin :validation_helpers

  def self.find_active_by_app_id(app_id:)
    where(app_id: app_id, active: true, verified: true, deleted_at: nil)
  end

  def valid_token?(token)
    verification_token == token && !verification_token_expired?
  end

  def self.generate_token
    SecureRandom.hex(3)[0, 5].upcase
  end

  def validate
    super
    validates_presence %i[app_id email]
    validates_format EMAIL, :email
  end

  def verification_token_expired?
    (Time.now.utc - verification_sent_at) > VERIFICATION_TOKEN_TTL
  end
end
