# EncryptedKeyValidator
#
# Custom validator for encrypted license keys
#
#   class License < ApplicationRecord
#     validates :encrypted_key, encrypted_key: true
#   end
#

class EncryptedKeyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.is_trial?

    unless valid_encrypted_key?(value)
      record.errors.add(attribute, :invalid_license_key)
    end
  end

  private

  def valid_encrypted_key?(value)
    LicenseKeyDecrypter.call(value)
  rescue OpenSSL::Cipher::CipherError, OpenSSL::PKey::RSAError
    false
  end
end
