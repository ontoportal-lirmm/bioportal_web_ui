namespace :flipper do
  desc "Rename a Flipper feature"
  task :rename, [:old_name, :new_name] => :environment do |t, args|
    old_key = args[:old_name]
    new_key = args[:new_name]
    
    unless old_key && new_key
      puts "Usage: rake flipper:rename[old_name,new_name]"
      puts "Example: rake flipper:rename['SPARQL Endpoint','SPARQL']"
      next
    end
    
    # Try different possible model names
    feature_class = nil
    
    # Check which model exists
    if defined?(Flipper::Adapters::ActiveRecord::Feature)
      feature_class = Flipper::Adapters::ActiveRecord::Feature
    elsif defined?(Flipper::Feature)
      feature_class = Flipper::Feature
    else
      # Try to find it by table name
      feature_class = Class.new(ActiveRecord::Base) do
        self.table_name = 'flipper_features'
      end
    end
    
    # Find the feature
    feature = feature_class.find_by(key: old_key)
    
    if feature
      if feature_class.exists?(key: new_key)
        puts "ERROR: Feature '#{new_key}' already exists!"
      else
        # Update feature
        feature.update!(key: new_key)
        
        # Update gates - also need to find the correct gate class
        gate_class = nil
        
        if defined?(Flipper::Adapters::ActiveRecord::Gate)
          gate_class = Flipper::Adapters::ActiveRecord::Gate
        else
          gate_class = Class.new(ActiveRecord::Base) do
            self.table_name = 'flipper_gates'
          end
        end
        
        updated_gates = gate_class.where(feature_key: old_key)
                                  .update_all(feature_key: new_key)
        
        puts "SUCCESS: Renamed '#{old_key}' to '#{new_key}'"
        puts "Updated #{updated_gates} gate records"
      end
    else
      puts "ERROR: Feature '#{old_key}' not found!"
    end
  end
end