require 'cgi'

class ConceptsController < ApplicationController
  include MappingsHelper
  include ConceptsHelper
  layout 'ontology'

  def show_concept
    params[:id] = params[:id] ? params[:id] : params[:conceptid]

    if params[:id].nil? || params[:id].empty?
      render :text => "Error: You must provide a valid concept id"
      return
    end

    # Note that find_by_acronym includes views by default
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    ontology_not_found(params[:ontology_id]) if @ontology.nil?

    @submission = get_ontology_submission_ready(@ontology)
    @ob_instructions = helpers.ontolobridge_instructions_template(@ontology)
    @concept = @ontology.explore.single_class({full: true, language: request_lang}, params[:id])
    @instances_concept_id = @concept.id

    concept_not_found(params[:id]) if @concept.nil?
    gather_details
    render :partial => 'show'
  end

  def show
    # Handle multiple methods of passing concept ids
    params[:id] = params[:id] ? params[:id] : params[:conceptid]

    if params[:id].nil? || params[:id].empty?
      render :text => "Error: You must provide a valid concept id"
      return
    end

    # Note that find_by_acronym includes views by default
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    @ob_instructions = helpers.ontolobridge_instructions_template(@ontology)

    if request.xhr?
      display = params[:callback].eql?('load') ? {full: true} : {display: "prefLabel"}
      @concept = @ontology.explore.single_class(display, params[:id])
      concept_not_found(params[:id]) if @concept.nil?
      @schemes = params[:concept_schemes]&.split(',')
      show_ajax_request # process an ajax call
    else
      # Get the latest 'ready' submission, or fallback to any latest submission
      # TODO: change the logic here if the fallback will crash the visualization
      @submission = get_ontology_submission_ready(@ontology)  # application_controller

      @concept = @ontology.explore.single_class({full: true}, params[:id])
      concept_not_found(params[:id]) if @concept.nil?
      @schemes = params[:concept_schemes].split(',')
      show_ajax_request # process a full call
    end
  end

  def show_label
    cls_id = params[:concept] || params[:id]  # cls_id should be a full URI
    ont_id = params[:ontology]  # ont_id could be a full URI or an acronym

    if ont_id.to_i > 0
      params_cleanup_new_api()
      stop_words = ["controller", "action"]
      redirect_to "#{request.path}#{params_string_for_redirect(params, stop_words: stop_words)}", :status => :moved_permanently
      return
    end

    render LabelLinkComponent.inline(cls_id, helpers.main_language_label(concept_label(ont_id, cls_id)))
  end

  def show_definition
    if params[:ontology].to_i > 0
      params_cleanup_new_api()
      stop_words = ["controller", "action"]
      redirect_to "#{request.path}#{params_string_for_redirect(params, stop_words: stop_words)}", :status => :moved_permanently
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find(params[:ontology])
    cls = @ontology.explore.single_class(params[:concept])
    render :text => cls.definition
  end

  def show_tree
    if params[:ontology].to_i > 0
      params_cleanup_new_api()
      stop_words = ["controller", "action"]
      redirect_to "#{request.path}#{params_string_for_redirect(params, stop_words: stop_words)}", :status => :moved_permanently
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    if @ontology.nil?
      ontology_not_found(params[:ontology])
    else 
      get_class(params) #application_controller
      render partial: 'ontologies/treeview', locals: { autoCLick: params[:auto_click] || true }
    end
  end

  def show_date_sorted_list
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    if @ontology.nil?
      ontology_not_found(params[:ontology])
    else
      page = params[:page]
      @last_date = params[:last_date]
      auto_click = page.to_s.eql?('1')
      params = {
        page: page,
        sortby:'modified,created',
        order:'desc,desc',
        display: 'prefLabel,modified,created',
        language: request_lang
      }
      if @last_date
        params.merge!(last_date: @last_date)
        @last_date = Date.parse(@last_date)
      end

      @page = @ontology.explore.classes(params)
      @concepts = filter_concept_with_no_date(@page.collection)
      @concepts_year_month = concepts_to_years_months(@concepts)

      render partial: 'concepts/date_sorted_list', locals: { auto_click: auto_click }
    end

  end

  def property_tree
    if params[:ontology].to_i > 0
      params_cleanup_new_api()
      stop_words = ["controller", "action"]
      redirect_to "#{request.path}#{params_string_for_redirect(params, stop_words: stop_words)}", :status => :moved_permanently
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    ontology_not_found(params[:ontology]) if @ontology.nil?
    @root = @ontology.property_tree
    render json: LinkedData::Client::Models::Property.properties_to_hash(@root.children)
  end

  # Renders a details pane for a given ontology/concept
  def details
    concept_not_found('') if params[:conceptid].nil? || params[:conceptid].empty?

    if params[:ontology].to_i > 0
      orig_id = params[:ontology]
      params_cleanup_new_api()
      options = {stop_words: ["controller", "action", "id"]}
      redirect_to "#{request.path.sub(orig_id, params[:ontology])}#{params_string_for_redirect(params, options)}", :status => :moved_permanently
      return
    end

    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    ontology_not_found(params[:ontology]) if @ontology.nil?

    @concept = @ontology.explore.single_class({full: true}, CGI.unescape(params[:conceptid]))
    concept_not_found(CGI.unescape(params[:conceptid])) if @concept.nil?

    if params[:styled].eql?("true")
      render :partial => "details", :layout => "partial"
    else
      render :partial => "details"
    end
  end


  def biomixer
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    ontology_not_found(params[:ontology]) if @ontology.nil?

    @concept = @ontology.explore.single_class({full: true}, params[:conceptid])
    concept_not_found(params[:conceptid]) if @concept.nil?

    @immediate_load = true

    render partial: "biomixer", layout: false
  end

# PRIVATE -----------------------------------------
private

  def show_ajax_request
    case params[:callback]
    when 'load' # Load pulls in all the details of a node
      gather_details
      render :partial => 'load'
    when 'children' # Children is called only for drawing the tree
      @children = @concept.explore.children(pagesize: 750, concept_schemes: @schemes.join(','), language: request_lang, display: 'prefLabel,obsolete,hasChildren').collection || []
      @children.sort! { |x, y| (x.prefLabel || "").downcase <=> (y.prefLabel || "").downcase } unless @children.empty?
      render :partial => 'child_nodes'
    end
  end

  # gathers the full set of data for a node
  def show_uri_request
    gather_details
    build_tree
  end

  def gather_details
    @notes = @concept.explore.notes
    update_tab(@ontology, @concept.id) #updates the 'history' tab with the current node
  end

  def build_tree
    # find path to root
    rootNode = @concept.explore.tree(include: "prefLabel,hasChildren,obsolete,subClassOf")
    @root = LinkedData::Client::Models::Class.new(read_only: true)
    @root.children = rootNode unless rootNode.nil?
  end

  def filter_concept_with_no_date(concepts)
    concepts.filter { |c| !concept_date(c).nil?}
  end

  def concepts_to_years_months(concepts)
    return unless concepts || concepts.nil?

    concepts.group_by { |c| concept_date(c).year }
            .transform_values do |items|
      items.group_by { |c| concept_date(c).strftime('%B') }
    end
  end
end
