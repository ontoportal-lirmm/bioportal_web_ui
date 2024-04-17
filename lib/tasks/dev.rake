# frozen_string_literal: true

namespace :dev do
  # Ensure tasks aren't executed against production-like environments
  task ensure_development_environment: :environment do
    abort 'Aborting: unsupported environment!' unless Rails.env.development?
  end

  namespace :appliance_users do
    desc 'Remove the contents of the virtual_appliance_users table'
    task reset: :environment do
      Rake::Task['dev:ensure_development_environment'].invoke
      VirtualApplianceUser.delete_all
      puts 'Done! The virtual_appliance_users table is empty.'
    end

    desc 'Populate the virtual_appliance_users table with sample data'
    task populate: :environment do
      Rake::Task['dev:ensure_development_environment'].invoke
      [
        { user_id: 'https://stagedata.bioontology.org/users/alexskr' },
        { user_id: 'https://stagedata.bioontology.org/users/fergerson' },
        { user_id: 'https://stagedata.bioontology.org/users/jonquet' },
        { user_id: 'https://stagedata.bioontology.org/users/paultest' },
        { user_id: 'https://stagedata.bioontology.org/users/rwynden' },
        { user_id: 'https://stagedata.bioontology.org/users/wangs' }
      ].each do |u|
        VirtualApplianceUser.find_or_create_by(u)
      end
      puts 'Done! The virtual_appliance_users table is populated.'
    end
  end
end
