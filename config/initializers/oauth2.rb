if $SSO_ENABLED
  Oauth2Controller.config do |config|

    idpMetadataJSON = JSON.parse(IO.read(Rails.root.join("config/oauth2/idp-configuration.json")), {symbolize_names: true})

    config.client_id = Rails.application.credentials.oauth2[:client_id]
    config.client_secret = Rails.application.credentials.oauth2[:client_secret]
    config.authorization_endpoint = idpMetadataJSON[:authorization_endpoint]
    config.token_endpoint = idpMetadataJSON[:token_endpoint]
    config.userinfo_endpoint = idpMetadataJSON[:userinfo_endpoint]
    config.end_session_endpoint = idpMetadataJSON[:end_session_endpoint]
  end
end
