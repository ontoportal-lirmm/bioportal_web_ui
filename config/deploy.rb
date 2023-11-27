set :author, "ontoportal-lirmm"
set :application, "bioportal_web_ui"

set :repo_url, "https://github.com/#{fetch(:author)}/#{fetch(:application)}.git"

set :deploy_via, :remote_cache

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# default deployment branch is master which can be overwritten with BRANCH env var
# BRANCH env var can be set to specific branch of tag, i.e 'v6.8.1'


# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/srv/ontoportal/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :error

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/bioportal_config.rb config/database.yml public/robots.txt}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache public/system public/assets config/locales}
set :linked_dirs, %w{log tmp/pids tmp/cache public/system public/assets}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
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
# If you want to restart using `passenger-config restart-app`, add this to your config/deploy.rb:
# set :passenger_restart_with_touch, false # Note that `nil` is NOT the same as `false` here
# If you don't set `:passenger_restart_with_touch`, capistrano-passenger will check what version of passenger you are running
# and use `passenger-config restart-app` if it is available in that version.

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options

SSH_JUMPHOST = ENV.include?('SSH_JUMPHOST') ? ENV['SSH_JUMPHOST'] : 'jumpbox.hostname.com'
SSH_JUMPHOST_USER = ENV.include?('SSH_JUMPHOST_USER') ? ENV['SSH_JUMPHOST_USER'] : 'username'

JUMPBOX_PROXY = "#{SSH_JUMPHOST_USER}@#{SSH_JUMPHOST}"
set :ssh_options, {
  user: 'ontoportal',
  forward_agent: 'true',
  keys: %w(config/deploy_id_rsa),
  auth_methods: %w(publickey),
  # use ssh proxy if UI servers are on a private network
  proxy: Net::SSH::Proxy::Command.new("ssh #{JUMPBOX_PROXY} -W %h:%p")
}

#private git repo for configuraiton
PRIVATE_CONFIG_REPO = ENV.include?('PRIVATE_CONFIG_REPO') ? ENV['PRIVATE_CONFIG_REPO'] : 'https://your_github_pat_token@github.com/your_organization/ontoportal-configs.git'
desc "Check if agent forwarding is working"
task :forwarding do
  on roles(:all) do |h|
    if test("env | grep SSH_AUTH_SOCK")
      info "Agent forwarding is up to #{h}"
    else
      error "Agent forwarding is NOT up to #{h}"
    end
  end
end

namespace :deploy do
  desc 'display remote system env vars'
  task :show_remote_env do
    on roles(:all) do
      remote_env = capture("env")
      puts remote_env
    end
  end

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
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end


  after :updating, :get_config
  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:app), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end
