begin
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # We're in smart spawning mode, so...
      # Close duplicated memcached connections - they will open themselves
      cache = Rails.cache.instance_variable_get("@data")
      cache.reset if cache && cache.respond_to?(:reset)
    end
  end
rescue NameError
  # In case you're not running under Passenger (i.e. devmode with mongrel)
end
