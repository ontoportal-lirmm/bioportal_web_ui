class LicenseKeyDecrypter < ApplicationService
  def initialize(license_key)
    @license_key = license_key
  end

  def call
    encrypted_key, encrypted_data = @license_key.split("|").map { |a| Base64.decode64(a) }

    public_key_file = Rails.root.join("config", "keys", "public.pem")
    public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))

    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.decrypt
    cipher.key = public_key.public_decrypt(encrypted_key)
    cipher.update(encrypted_data) + cipher.final
  end
end
