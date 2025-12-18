require Rails.root.join('app/lib/flipper/flipper_setup')

Flipper::UI.configure do |config|
  config.banner_text = "#{ENV["RAILS_ENV"].capitalize} Environment"
  config.banner_class = 'danger'
end

FlipperSetup.configure!