if $BUGSNAG_API_KEY
  Bugsnag.configure do |config|
    config.api_key = $BUGSNAG_API_KEY
  end
end
