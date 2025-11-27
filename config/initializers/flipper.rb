require 'flipper/adapters/active_record'
require 'json'
Flipper.configure do |config|
  config.default do
    flipper = Flipper.new(Flipper::Adapters::ActiveRecord.new)
    defaults_path = Rails.root.join('config/flipper.json')
    if File.exist?(defaults_path)
      json = JSON.parse(File.read(defaults_path))
      (json['features'] || {}).each do |name, cfg|
        if cfg['boolean'] == true || cfg['boolean'] == 'true'
          flipper.enable(name)
        end
      end
    end
    flipper
  end
end

Flipper.register(:admins) do |actor, context|
  actor.respond_to?(:admin?) && actor.admin?
end