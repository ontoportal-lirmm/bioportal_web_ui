# app/lib/flipper_setup.rb
module FlipperSetup
  FEATURES = ["Agents", "SPARQL Endpoint"].freeze

  def self.configure!
    Flipper.configure do |config|
      config.default do
        primary_adapter = Flipper::Adapters::ActiveRecord.new 

        flipper = Flipper.new(Flipper::Adapters::ActiveSupportCacheStore.new(
            primary_adapter, 
            Rails.cache, 
            10.minutes
          )
        )
        FEATURES.each { |f| flipper.enable(f) }

        flipper
      end
    end
  end



  def self.enable_feature(name)
    Flipper.enable(name)
  end

  def self.disable_feature(name)
    Flipper.disable(name)
  end
end