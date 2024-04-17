# frozen_string_literal: true

# VirtualApplianceIdValidator
#
# Custom validator for virtual appliance IDs. The virtual appliance ID in a
# license key must match the ID of the virtual appliance against which a
# license is submitted.
#
#   class License < ApplicationRecord
#     validates :encrypted_key, virtual_appliance_id: true
#   end
#
class VirtualApplianceIdValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.is_trial?

    response = JSON.parse(
      LinkedData::Client::HTTP.get("#{LinkedData::Client.settings.rest_url}/admin/update_info", {}, raw: true)
    )
    if response['appliance_id'].blank?
      record.errors.add(attribute, :no_appliance_id_for_comparison)
      return false
    end

    unless valid_virtual_appliance_id?(value, response['appliance_id'])
      record.errors.add(attribute, :appliance_id_mismatch)
    end
  end

  private

  def valid_virtual_appliance_id?(value, appliance_id)
    decrypted_key = LicenseKeyDecrypter.call(value)
    decrypted_appliance_id = decrypted_key.split(';')[0]
    appliance_id.eql?(decrypted_appliance_id)
  rescue OpenSSL::Cipher::CipherError, OpenSSL::PKey::RSAError
    false
  end
end
