set :branch, 'master'
set :server, 'ecoportal.lifewatch.eu'

server fetch(:server), user: fetch(:user), roles: %w{web app}

set :ssh_options, {
  user: 'ontoportal',
  forward_agent: 'true',
  #keys: %w(config/deploy_id_rsa),
  #auth_methods: %w(publickey),
  # use ssh proxy if UI servers are on a private network
  #proxy: Net::SSH::Proxy::Command.new('ssh deployer@sshproxy.ontoportal.org -W %h:%p')
}
