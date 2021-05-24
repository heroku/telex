require "openssl"

module Telex::ApiKey
  extend self

  def encrypt(raw_key)
    OpenSSL::HMAC.hexdigest("sha512", Config.api_key_hmac_secret, raw_key)
  end

  def compare(encrypted_key, given_key)
    time_constant_compare(encrypted_key, encrypt(given_key))
  end

  private

  def time_constant_compare(a, b)
    check = a.bytesize ^ b.bytesize
    a.bytes.zip(b.bytes) { |x, y| check |= x ^ y }
    check == 0
  end
end
