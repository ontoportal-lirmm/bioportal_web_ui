require "cube"

##
# This enables collection of request statistics for anaylsis via cube.
# A cube server is required. See http://square.github.io/cube/ for more info.
module Rack
  class CubeReporter
    def initialize(app = nil, options = {})
      host = options[:cube_host] || "localhost"
      port = options[:cube_port] || 1180
      @app = app
      @cube = ::Cube::Client.new(host, port)
    end

    def call(env)
      start = Time.now
      data = @app.call(env)
      finish = Time.now
      user = env["rack.session"] ? env["rack.session"][:user] : nil
      apikey = user.apikey if user
      username = user.username if user
      req_data = {
        duration_ms: ((finish - start) * 1000).ceil,
        path: env["REQUEST_PATH"],
        status: data[0],
        user: {
          apikey: apikey,
          username: username,
          ip: env["REMOTE_ADDR"],
          user_agent: env["HTTP_USER_AGENT"],
        },
      }
      @cube.send "ui_request", DateTime.now, req_data
      data
    end
  end
end

if global_variables.include?(:$ENABLE_CUBE) && $ENABLE_CUBE == true
  Rails.configuration.middleware.use(::Rack::CubeReporter, { cube_host: $CUBE_HOST, cube_port: $CUBE_PORT })
end
