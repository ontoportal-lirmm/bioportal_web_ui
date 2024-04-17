# frozen_string_literal: true

require 'rails_helper'

RSpec.describe License, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  before(:all) do
    @stage_server_appliance_id = '75872ccc-5019-4733-ac34-01ca7b8bcb3f'

    response = JSON.parse(
      LinkedData::Client::HTTP.get('https://stagedata.bioontology.org/admin/update_info', {}, raw: true)
    )
    unless response['appliance_id'].eql?(@stage_server_appliance_id)
      puts "\nStaging server appliance ID has changed from %s to %s." % [@stage_server_appliance_id,
                                                                         response['appliance_id']]
      puts 'Test license generated with the old appliance ID will no longer validate.'
      puts "Stopping test suite...\n\n"
      exit
    end
  end

  # Decryption of below variable: "841b4f58-02e1-4a66-9e27-191f15e16279;Microsoft Corporation;2021-02-14".
  let(:encrypted_license_key) {
    <<~HEREDOC
      ds938nK0sdu8AzhtGefz0r7JTH97ncQfuokmwYLGHYbQF4CA1lWVHWwWoM/W\
      lzvZlDSE/WSLvXKefOXk6+yrelKgUMcnLy1Q5o6E+jJW6uia77Ivv6Hxl445\
      0kB8CeywyTTOQhROvQZ9NGsl5hpriNlaNlZHqo7gVtBZReoDypciUS+562On\
      x+CiYKl18bCOD7LmlJCyGg662EUPX5gwGORxKYYs/+tQixQ49LTg8dI/XguK\
      r/FIqUuz4erA73Le4Jn2C3dE2KjvS15DKIzwYL18oe+eONAPGj4JOredwk76\
      jHGa5fHNAmoSOB3jF6sboQK8nG/LajuFEI+O6fWXUQ==\
      |a6Bh755yqiviJBFm/XAMS/lA1hhYjR5SKrnQ5vb4/osMutu91j9Z/BSNIknD\
      Ia5kNAhlV6Ie0UkjjMbRgAr471TdLFcy2fB05BwG14JU1GM=
    HEREDOC
  }

  # This license key was generated using the staging license server, and the
  # encoded appliance ID matches that of the BioPortal staging environment.
  #
  # Staging license server: https://license.stage.ontoportal.org
  # Staging BioPortal instance: https://stage.bioontology.org/
  # License information for this encrypted key: https://license.stage.ontoportal.org/licenses/1078
  #
  # Decryption of below variable:
  #   "75872ccc-5019-4733-ac34-01ca7b8bcb3f;Stanford Center for Biomedical Informatics;2021-04-21"
  #
  let(:encrypted_license_key_staging_env) {
    <<~HEREDOC
      bx93dtaUF/SzXgIcAQHtKowDdTil4pO1lU/bL49+5yN9VfE4qweEdEm7/BXH
      MFEhIyhdegGBeTFgMuxjQeBlcl1IGPIgHg3RDaUDEu6Kp0TSBfPLhaUgmf0s
      aeBkhmOpJ/hvHtOXRe8Vcy1003um7d0Lb5OCDPMq1GIONm5MUa8syJkftOoY
      ERJGlFWReWYgaPYua6opvn0kzu/kNKRFO8bqcuRfyrWNchxeHUwj1ayGiXmT
      eym1jcD6Vzzd4DmvfP7z7a+u7xJjXKFGyy885mfX7TcSMuD1pQko4DRTfrCJ
      g/jNgRpOdoMvCXt/B1zPwY9vV/pBw0mOpanjWAjC7g==
      |I7SRc0ymvXcB7yQJ+6radcth3h2NKYtvzYfohP4yHck4qn69oK3mvl5TvJ+R
      OTJe7jgOUk6hQ8vn3yozG+9nFwsp6vgHgGSiah5UBAsqlFB4uRxcMM4ZM4iD
      6X+O75eZ
    HEREDOC
  }

  it 'decrypts license data' do
    license = License.create(encrypted_key: encrypted_license_key_staging_env)

    expect(license.appliance_id).to eq(@stage_server_appliance_id)
    expect(license.organization).to eq('Stanford Center for Biomedical Informatics')
    expect(license.expiry_date).to eq(Date.parse('2021-04-21'))
  end

  it 'is a trial license' do
    license = License.new(encrypted_key: 'trial', created_at: Time.current)

    expect(license.is_trial?).to eq(true)
  end

  it 'is not a trial license' do
    license = License.new(encrypted_key: encrypted_license_key)

    expect(license.is_trial?).to eq(false)
  end

  it 'is in trial period' do
    license = License.create(encrypted_key: 'trial', created_at: Time.current)

    travel 15.days do
      expect(license.days_remaining).to be > 0
    end
  end

  it 'is out of trial after trial period' do
    license = License.create(encrypted_key: 'trial', created_at: Time.current)

    travel 31.days do
      expect(license.days_remaining).to eq(0)
    end
  end

  it 'calculates days remaining' do
    license = License.create(encrypted_key: encrypted_license_key_staging_env)

    travel_to(Date.parse('2021-03-22')) do
      expect(license.days_remaining).to eq(30)
    end

    travel_to(Date.parse('2021-04-20')) do
      expect(license.days_remaining).to eq(1)
    end

    travel_to(Date.parse('2021-04-21')) do
      expect(license.days_remaining).to eq(0)
    end

    travel_to(Date.parse('2021-05-01')) do
      expect(license.days_remaining).to eq(0)
    end
  end

  describe 'validation' do
    let(:encrypted_license_key_with_missing_characters) {
      <<~HEREDOC
        ds938nK0sdu8AzhtGefz0r7JTH97ncQfuokmwYLGHYbQF4CA1lWVHWwWoM/W\
        lzvZlDSE/WSLvXKefOXk6+yrelKgUMcnLy1Q5o6E+jJW6uia77Ivv6Hxl445\
        0kB8CeywyTTOQhROvQZ9NGsl5hpriNlaNlZHqo7gVtBZReoDypciUS+562On\
        x+CiYKl18bCOD7LmlJCyGg662EUPX5gwGORxKYYs/+tQixQ49LTg8dI/XguK\
        r/FIqUuz4erA73Le4Jn2C3dE2KjvS15DKIzwYL18oe+eONAPGj4JOredwk76\
        jHGa5fHNAmoSOB3jF6sboQK8nG/LajuFEI+O6fWXUQ==\
        |a6Bh755yqiviJBFm/XAMS/lA1hhYjR5SKrnQ5vb4/osMutu91j9Z/BSNIknD\
        Ia5kNAhlV6Ie0UkjjMbRgAr471TdLFcy2fB05BwG14JU
      HEREDOC
    }

    it 'blocks malformed keys' do
      license = License.new(encrypted_key: encrypted_license_key_with_missing_characters)

      license.valid?

      expect(license).to be_invalid
      expect(license.errors[:encrypted_key])
        .to include(I18n.t('activerecord.errors.models.license.attributes.encrypted_key.invalid_license_key'))
    end

    it 'blocks invalid keys' do
      license = License.create(encrypted_key: 'lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do \
                                               eiusmod tempor incididunt ut labore et dolore magna aliqua')

      license.valid?

      expect(license).to be_invalid
      expect(license.errors[:encrypted_key])
        .to include(I18n.t('activerecord.errors.models.license.attributes.encrypted_key.invalid_license_key'))
    end

    it 'allows trial licenses' do
      license = License.new(encrypted_key: 'trial')

      license.valid?

      expect(license).to be_valid
      expect(license.errors).to be_empty
    end

    it 'allows valid keys' do
      license = License.new(encrypted_key: encrypted_license_key_staging_env)

      license.valid?

      expect(license).to be_valid
      expect(license.errors).to be_empty
    end

    it 'blocks licenses with mismatches between encoded appliance IDs and actual' do
      license = License.new(encrypted_key: encrypted_license_key)

      license.save

      expect(license.errors[:encrypted_key]).to include 'is an appliance ID mismatch'
    end
  end

  describe '.current_license' do
    it 'should return the latest license' do
      License.create(encrypted_key: encrypted_license_key_staging_env, created_at: Time.now + 1.day)
      newer_license = License.create(encrypted_key: encrypted_license_key_staging_env, created_at: Time.now + 2.days)

      expect(License.current_license.count).to eql(1)
      expect(License.current_license.first).to eql(newer_license)
    end
  end
end
