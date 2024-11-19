set :author, "lifewatch-eric"
set :application, "ecoportal_web_ui"
set :rails_env, "appliance"
set :repo_url, "https://github.com/#{fetch(:author)}/#{fetch(:application)}.git"

set :deploy_via, :remote_cache



# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/srv/ontoportal/bioportal_web_ui"

# Default value for :log_level is :debug
set :log_level, :error

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache}
append :linked_files, 'config/database.yml', 'config/bioportal_config_appliance.rb'
append :linked_files, 'config/secrets.yml', 'config/site_config.rb','config/credentials/appliance.key', 'config/credentials/appliance.yml.enc'


set :keep_releases, 5
set :bundle_without, 'development:test'
set :bundle_config, { deployment: true }
set :rails_env, "appliance"
set :config_folder_path, "#{fetch(:application)}/#{fetch(:stage)}"
# Defaults to [:web]
set :assets_roles, [:web, :app]
set :keep_assets, 3

# If you want to restart using `touch tmp/restart.txt`, add this to your config/deploy.rb:

set :passenger_restart_with_touch, true


namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart
end
