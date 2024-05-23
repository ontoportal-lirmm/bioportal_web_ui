# frozen_string_literal: true

class HomeController < ApplicationController
  layout :determine_layout


  include FairScoreHelper

  def index
    @analytics =  helpers.ontologies_analytics
    # Calculate BioPortal summary statistics
    @ont_count = @analytics.keys.size
    metrics = LinkedData::Client::Models::Metrics.all
    metrics = metrics.each_with_object(Hash.new(0)) do |h, sum|
      h.to_hash.slice(:classes, :properties, :individuals).each { |k, v| sum[k] += v }
    end

    @cls_count = metrics[:classes]
    @individuals_count = metrics[:individuals]
    @prop_count = metrics[:properties]
    @map_count = total_mapping_count
    @projects_count = LinkedData::Client::Models::Project.all.length
    @users_count = LinkedData::Client::Models::User.all.length

    @upload_benefits = [
      t('home.benefit1'),
      t('home.benefit2'),
      t('home.benefit3'),
      t('home.benefit4'),
      t('home.benefit5')
    ]

    @anal_ont_names = []
    @anal_ont_numbers = []
    @analytics.sort_by{|ont, count| -count}[0..4].each do |ont, count|
      @anal_ont_names << ont
      @anal_ont_numbers << count
    end

  end

  def tools
    @tools = {
      search: {
        link: "search/ontologies/content",
        icon: "icons/search.svg",
        title: t('tools.search.title'),
        description: t('tools.search.description'),
      },
      converter: {
        link: "/content_finder",
        icon: "icons/settings.svg",
        title: t('tools.converter.title'),
        description: t('tools.converter.description'),
      },
      url_checker: {
        link: check_resolvability_path,
        icon: "check.svg",
        title: t('tools.url_checker.title'),
        description: t('tools.url_checker.description')
      }
    }

    @title = "#{helpers.portal_name} #{t('layout.footer.tools')}"
    render 'tools', layout: 'tool'
  end

  def all_resources
    @conceptid = params[:conceptid]
    @ontologyid = params[:ontologyid]
    @ontologyversionid = params[:ontologyversionid]
    @search = params[:search]
  end

  def feedback
    # Show the header/footer or not
    feedback_layout = params[:pop].eql?('true') ? 'popup' : 'ontology'

    # We're using a hidden form field to trigger for error checking
    # If sim_submit is nil, we know the form hasn't been submitted and we should
    # bypass form processing.
    if params[:sim_submit].nil?
      render 'home/feedback/feedback', layout: feedback_layout
      return
    end

    @tags = []
    unless params[:bug].nil? || params[:bug].empty?
      @tags << t('home.bug')
    end
    unless params[:proposition].nil? || params[:proposition].empty?
      @tags << t('home.proposition')
    end
    unless params[:question].nil? || params[:question].empty?
      @tags << t('home.question')
    end
    unless params[:ontology_submissions_request].nil? || params[:ontology_submissions_request].empty?
      @tags << t('home.ontology_submissions_request')
    end

    @errors = []

    if params[:name].nil? || params[:name].empty?
      @errors << t('home.include_name')
    end
    if params[:email].nil? || params[:email].length < 1 || !params[:email].match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i)
      @errors << t('home.include_email')
    end
    if params[:comment].nil? || params[:comment].empty?
      @errors << t('home.include_comment')
    end
    if using_captcha? && !session[:user]
      unless verify_recaptcha
        @errors << t('home.fill_text')
      end
    end

    unless @errors.empty?
      render 'home/feedback/feedback', layout: feedback_layout
      return
    end

    Notifier.feedback(params[:name], params[:email], params[:comment], params[:location], @tags).deliver_later

    if params[:pop].eql?('true')
      render 'home/feedback/feedback_complete', layout: 'popup'
    else
      flash[:notice] = t('home.notice_feedback')
      redirect_to_home
    end
  end


  def site_config
    render json: bp_config_json
  end

  def account
    @title = t('home.account_title')
    if session[:user].nil?
      redirect_to controller: 'login', action: 'index', redirect: '/account'
      return
    end

    @user = LinkedData::Client::Models::User.get(session[:user].id, include: 'all')

    @user_ontologies = @user.customOntology
    @user_ontologies ||= []

    onts = LinkedData::Client::Models::Ontology.all(include_views: true);
    @admin_ontologies = onts.select { |o| o.administeredBy.include? @user.id }

    projects = LinkedData::Client::Models::Project.all
    @user_projects = projects.select { |p| p.creator.include? @user.id }

    render 'users/show'
  end

  def feedback_complete; end

  def annotator_recommender_form
    if params[:submit_button] == "annotator"
      redirect_to "/annotator?text=#{helpers.escape(params[:text])}"
    elsif params[:submit_button] == "recommender"
      redirect_to "/recommender?input=#{helpers.escape(params[:input])}"
    end
  end

  private

  # Dr. Musen wants 5 specific groups to appear first, sorted by order of importance.
  # Ordering is documented in GitHub: https://github.com/ncbo/bioportal_web_ui/issues/15.
  # All other groups come after, with agriculture in the last position.
  def organize_groups
    # Reference: https://lildude.co.uk/sort-an-array-of-strings-by-severity
    acronyms = %w[UMLS OBO_Foundry WHO-FIC CTSA caBIG]
    size = @groups.size
    @groups.sort_by! { |g| acronyms.find_index(g.acronym[/(UMLS|OBO_Foundry|WHO-FIC|CTSA|caBIG)/]) || size }

    others, agriculture = @groups.partition { |g| g.acronym != 'CGIAR' }
    @groups = others + agriculture
  end
end
