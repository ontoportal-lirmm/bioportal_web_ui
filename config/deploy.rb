set :author, "ontoportal-lirmm"
set :application, "bioportal_web_ui"

set :repo_url, "https://github.com/#{fetch(:author)}/#{fetch(:application)}.git"

set :deploy_via, :remote_cache

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# default deployment branch is master which can be overwritten with BRANCH env var
# BRANCH env var can be set to specific branch of tag, i.e 'v6.8.1'


# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/opt/ontoportal/#{fetch(:application)}"

# Default value for :log_level is :debug
set :log_level, :error

# Default value for :linked_files is []
append :linked_files, 'config/database.yml', 'config/bioportal_config_appliance.rb'
append :linked_files, 'config/secrets.yml', 'config/credentials/appliance.key', 'config/credentials/appliance.yml.enc'

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets public/system public/assets}

# Default value for default_env is {}
set :default_env, {
  'PATH' => "/usr/local/rbenv/shims:/usr/local/rbenv/bin:/usr/bin:$PATH"
}

# set bundle options
set :bundle_flags, "--verbose"

# Default value for keep_releases is 5
set :keep_releases, 5
set :bundle_without, 'development:test'
set :bundle_config, { deployment: true }
set :rails_env, "appliance"
set :config_folder_path, "#{fetch(:application)}/#{fetch(:stage)}"
# Defaults to [:web]
set :assets_roles, [:web, :app]
set :keep_assets, 3

# SSH_JUMPHOST = ENV.include?('SSH_JUMPHOST') ? ENV['SSH_JUMPHOST'] : 'jumpbox.hostname.com'
# SSH_JUMPHOST_USER = ENV.include?('SSH_JUMPHOST_USER') ? ENV['SSH_JUMPHOST_USER'] : 'username'
# JUMPBOX_PROXY = "#{SSH_JUMPHOST_USER}@#{SSH_JUMPHOST}"

set :ssh_options, {
  user: 'ontoportal',
  # forward_agent: 'true',
  # keys: %w(config/deploy_id_rsa),
  # auth_methods: %w(publickey),
  # proxy: Net::SSH::Proxy::Command.new("ssh #{JUMPBOX_PROXY} -W %h:%p")
}

#private git repo for configuraiton
# PRIVATE_CONFIG_REPO = ENV.include?('PRIVATE_CONFIG_REPO') ? ENV['PRIVATE_CONFIG_REPO'] : 'https://your_github_pat_token@github.com/your_organization/ontoportal-configs.git'

namespace :deploy do
  desc 'Incorporate the bioportal_conf private repository content'
  # Get cofiguration from repo if PRIVATE_CONFIG_REPO env var is set
  # or get config from local directory if LOCAL_CONFIG_PATH env var is set
  task :get_config do
    if defined?(PRIVATE_CONFIG_REPO)
      TMP_CONFIG_PATH = "/tmp/#{SecureRandom.hex(15)}".freeze
      on roles(:app) do
        execute "git clone -q #{PRIVATE_CONFIG_REPO} #{TMP_CONFIG_PATH}"
        execute "rsync -a #{TMP_CONFIG_PATH}/#{fetch(:config_folder_path)}/ #{release_path}/"
        execute "rm -rf #{TMP_CONFIG_PATH}"
      end
    elsif defined?(LOCAL_CONFIG_PATH)
      on roles(:app) do
        execute "rsync -a #{LOCAL_CONFIG_PATH}/#{fetch(:application)}/ #{release_path}/"
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo systemctl restart ui.service'
    end
  end


  after :updating, :get_config
  after :publishing, :restart
end
