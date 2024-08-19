set :branch, 'master'
set :server, 'biodivportal.gfbio.dev'

server fetch(:server), user: fetch(:user), roles: %w{web app}

set :ssh_options, {
  user: 'ontoportal',
  forward_agent: 'true',
  port: 30082
  #keys: %w(config/deploy_id_rsa),
  #auth_methods: %w(publickey),
  # use ssh proxy if UI servers are on a private network
  #proxy: Net::SSH::Proxy::Command.new('ssh deployer@sshproxy.ontoportal.org -W %h:%p')
}
