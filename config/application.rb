require_relative 'boot'

require 'rails/all'
require_relative './local_logger'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BioportalWebUi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Serve error pages from the Rails app itself, instead of using static error pages in /public.
    config.exceptions_app = self.routes

    config.settings = config_for(:settings)
  end
end
