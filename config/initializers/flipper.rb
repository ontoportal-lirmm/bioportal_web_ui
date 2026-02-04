require Rails.root.join('app/lib/flipper/flipper_setup')

Flipper::UI.configure do |config|
  env = Rails.env.presence || ENV["RAILS_ENV"].presence || "development"
  env_display_map = {
    "appliance" => "Production",
    "development" => "Development"
  }
  env_class_map = {
    "appliance" => "danger",
    "development" => "info",
  }
  
  config.banner_text = "#{env_display_map[env] || env.titleize} Environment"
  config.banner_class = env_class_map[env] || "secondary"
end

FlipperSetup.configure!