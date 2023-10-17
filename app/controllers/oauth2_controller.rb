class Oauth2Controller < ApplicationController

  skip_before_action :verify_authenticity_token

  def index
    # Sets the redirect properties
    if params[:redirect]
      # Get the original, encoded redirect
      uri = URI.parse(request.url)
      orig_params = Hash[uri.query.split("&").map {|e| e.split("=",2)}].symbolize_keys
      session[:redirect] = orig_params[:redirect]
    else
      session[:redirect] = request.referer
    end

    redirect_to login_index_path
  end

  def login

    client = build_oauth2_client

    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    # Authorization Request
    authorization_uri = client.authorization_uri(
      scope: [],
      state: session[:state],
      nonce: session[:nonce]
    )
    redirect_to authorization_uri, allow_other_host: true
  end

  def authorize_callback
    # Parameter checking
    code = params[:code]
    state = params[:state]

    @errors = []

    if code.nil?
      @errors.append("Missing <code>code</code> argument in the callback from the Identity Provider")
    end

    if state.nil?
      @errors.append("Missing <code>state</code> argument in the callback from the Identity Provider")
    end

    if state != session[:state]
      @errors.append("The <code>state</code> argument in the callback from the Identity Provider does not match the expected value")
    end

    unless @errors.empty?
      flash[:notice] = @errors.join("<br>").html_safe
      redirect_to_home
    end

    # Request tokens
    client = build_oauth2_client
    client.authorization_code = code

    access_token = client.access_token!

    # Authenticate the user with the access token to obtain the apikey
    #
    logged_in_user = LinkedData::Client::HTTP.post("#{LinkedData::Client.settings.rest_url}/users/authenticate", { token: access_token.access_token })
    logged_in_user.id_token = access_token.id_token

    if logged_in_user && !logged_in_user.errors
      loginInternal(logged_in_user)
      redirect = "/"

      if session[:redirect]
        redirect = CGI.unescape(session[:redirect])
      end

      redirect_to redirect
    else
      errorMsg = "Login Failed"
      if logged_in_user&.errors
        errorMsg += "<br>"
        errorMsg += logged_in_user.errors.join("<br>")
      end
      flash[:error] = errorMsg.html_safe
      redirect_to_home
    end
  end

  def loginInternal(user)
    return unless user
    session[:user] = user
    custom_ontologies_text = session[:user].customOntology && !session[:user].customOntology.empty? ? "The display is now based on your <a href='/account#custom_ontology_set'>Custom Ontology Set</a>." : ""
    notice = "Welcome <b>" + user.username.to_s + "</b>! " + custom_ontologies_text
    flash[:success] = notice.html_safe
  end

  def logout

    redirect = request.referer || "/"
    external_redirect_allowed = false

    # Delete internal security context

    if session[:admin_user]
      old_user = session[:user]
      session[:user] = session[:admin_user]
      session.delete(:admin_user)
      flash[:success] = "Logged out <b>#{old_user.username}</b>, returned to <b>#{session[:user].username}</b>".html_safe
    else
      idt = session[:user]&.id_token

      session[:user] = nil
      flash[:success] = "You have successfully logged out"

      if redirect == "/"
        redirect =  request.protocol + request.host_with_port + "/"
      end
      redirect = build_url_with_params(@@configStruct.end_session_endpoint, {client_id: @@configStruct.client_id, id_token_hint: idt, post_logout_redirect_uri: redirect})
    end

    # Start an RP-initiated logout process
    redirect_to redirect, allow_other_host: true
  end

  def self.config(&block)
    raise "missing code block" unless block_given?
    @@configStruct = OpenStruct.new

    yield @@configStruct
  end

  private

  def build_oauth2_client
    raise 'OAUTH2 has not been configured' unless @@configStruct
    OpenIDConnect::Client.new(
      identifier: @@configStruct.client_id,
      secret: @@configStruct.client_secret,
      redirect_uri: request.protocol + request.host_with_port + "/oauth2/authorize_callback",
      host: @@configStruct.host,
      authorization_endpoint: @@configStruct.authorization_endpoint,
      token_endpoint: @@configStruct.token_endpoint,
      userinfo_endpoint: @@configStruct.userinfo_endpoint
    )
  end

  def build_url_with_params(url, params)
    # See https://stackoverflow.com/a/26867426
    uri = URI.parse(url)
    new_query_ar = URI.decode_www_form(uri.query || '')
    params.each_key { |k| new_query_ar << [k, params[k]] }
    uri.query = URI.encode_www_form(new_query_ar)
    uri.to_s
  end
end