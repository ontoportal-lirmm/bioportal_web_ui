require 'uri'

class SearchController < ApplicationController

  skip_before_action :verify_authenticity_token

  layout :determine_layout

  def index
    @search_query = params[:query].nil? ? params[:q] : params[:query]
    params[:q] = params[:query]
    params[:query] = nil
    @search_query ||= ""
    @advanced_options_open = false
    unless @search_query.eql?("")
      params[:pagesize] = "5000"
      define_search_api_params(params)
      @advanced_options_open = !params_empty?(params) 
      @select_ontologies = params[:ontologies_list]
      @select_categories = params[:categories_list]
      data = LinkedData::Client::Models::Class.search(@search_query, params)
      results = data.collection
      grouped_results =  group_results_by_ontology(results)
      @search_results = make_search_result(grouped_results)
      @no_results = @search_results.eql?([])
      end
    end
  end

  def json_search
    if params[:q].nil?
      render :text => "No search class provided"
      return
    end
    check_params_query(params)
    check_params_ontologies(params)  # Filter on ontology_id
    search_page = LinkedData::Client::Models::Class.search(params[:q], params)
    @results = search_page.collection

    response = ""
    obsolete_response = ""
    separator = (params[:separator].nil?) ? "~!~" : params[:separator]
    for result in @results
      # TODO_REV: Format the response with type information, target information
      # record_type = format_record_type(result[:recordType], result[:obsolete])
      record_type = ""

      target_value = result.prefLabel.select{|x| x.include?( params[:q].delete('*'))}.first || result.prefLabel.first

      case params[:target]
        when "name"
          target_value = result.prefLabel
        when "shortid"
          target_value = result.id
        when "uri"
          target_value = result.id
      end

      json = []
      json << "#{target_value}"
      json << " [obsolete]" if result.obsolete? # used by JS in ontologies/visualize to markup obsolete classes
      json << "|#{result.id}"
      json << "|#{record_type}"
      json << "|#{result.explore.ontology.acronym}"
      json << "|#{result.id}" # Duplicated because we used to have shortId and fullId
      json << "|#{target_value}"
      # This is nasty, but hard to workaround unless we rewrite everything (form_autocomplete, jump_to, crossdomain_autocomplete)
      # to use JSON from the bottom up. To avoid this, we pass a tab separated column list
      # Columns: synonym
      json << "|#{(result.synonym || []).join(";")}"
      if params[:id] && params[:id].split(",").length == 1
        json << "|#{CGI.escape((result.definition || []).join(". "))}#{separator}"
      else
        json << "|#{result.explore.ontology.name}"
        json << "|#{result.explore.ontology.acronym}"
        json << "|#{CGI.escape((result.definition || []).join(". "))}#{separator}"
      end

      # Obsolete results go at the end
      if result.obsolete?
        obsolete_response << json.join
      else
        response << json.join
      end
    end

    # Obsolete results merge
    response << obsolete_response

    content_type = "text/html"
    if params[:response].eql?("json")
      response = response.gsub("\"","'")
      response = "#{params[:callback]}({data:\"#{response}\"})"
      content_type = "application/javascript"
    end

    render plain: response, content_type: content_type
  end


  private

  def check_params_query(params)
    params[:q] = params[:q].strip
    params[:q] = params[:q] + '*' unless params[:q].end_with?("*") # Add wildcard
  end

  def check_params_ontologies(params)
    params[:ontologies] ||= params[:id]
    if params[:ontologies]
      if params[:ontologies].include?(",")
        params[:ontologies] = params[:ontologies].split(",")
      else
        params[:ontologies] = [params[:ontologies]]
      end
      if params[:ontologies].first.to_i > 0
        params[:ontologies].map! {|o| BpidResolver.id_to_acronym(o)}
      end
      params[:ontologies] = params[:ontologies].join(",")
    end
  end

  def format_record_type(record_type, obsolete = false)
    case record_type
      when "apreferredname"
        record_text = "Preferred Name"
      when "bconceptid"
        record_text = "Class ID"
      when "csynonym"
        record_text = "Synonym"
      when "dproperty"
        record_text = "Property"
      else
        record_text = ""
    end
    record_text = "Obsolete Class" if obsolete
    record_text
  end

  def group_results_by_ontology(results)
    results.group_by { |element| element['links']['ontology'] }
  end

  def make_search_result(grouped_results)
    search_results = []
    grouped_results = add_reuses_to_structure(grouped_results)
    grouped_results = add_ontology_reuses(grouped_results)

    
    grouped_results.each_key do |key|
      ontology_classes = grouped_results[key][:classes]
      element_pref_lab = get_closest_preflab(ontology_classes[0].prefLabel) 
      element_id = ontology_classes[0].id
      element_ontology_uri = ontology_classes[0].links['ontology']
      element_ontology_name_acronym = get_ontology_name_acronym_by_uri(element_ontology_uri)
      ui_link = ontology_classes[0].links['ui']
      end_point = get_after_last_slash(ui_link)
      element_link = "/ontologies/#{end_point}"
      
      element_definition = get_element_defintion(ontology_classes[0].definition) 
      
      decendents = []
      ontology_classes.each_with_index do |e , index|
        next if index == 0
        e_pref_lab = get_closest_preflab(e.prefLabel) 
        e_id = e.id
        e_ui_link = e.links['ui']
        e_definition = get_element_defintion(e.definition)
        e_end_point = get_after_last_slash(e_ui_link)
        e_link = "/ontologies/#{e_end_point}"
        decendents_list_element = {preflab: e_pref_lab,id: e_id, link: e_link, definition: e_definition}
        decendents.push(decendents_list_element)
      end

      reuses = []
      ontology_reuses = grouped_results[key][:reuses]
      ontology_reuses.each do |reuse|
        reuses_list_element = {title: nil, decendants: []}
        title_element = {preflab: 'test', ontology: nil, id: nil, link: nil, definition: nil}
        reuse_ontology_uri = reuse[:id]
        reuse_preflab = get_closest_preflab(reuse[:classes][0].prefLabel)
        reuse_ontology_name_acronym = get_ontology_name_acronym_by_uri(reuse_ontology_uri)
        reuse_id = reuse[:classes][0].id
        r_link = get_after_last_slash(reuse[:classes][0].links['ui'])
        reuse_link = "/ontologies/#{r_link}"
        reuse_definition = get_element_defintion(reuse[:classes][0].definition)
        title_element[:ontology] = reuse_ontology_name_acronym
        title_element[:preflab] = reuse_preflab
        title_element[:id] = reuse_id
        title_element[:link] = reuse_link
        title_element[:definition] = reuse_definition
        reuses_list_element[:title] = title_element
        reuse_decendents_list = []
        reuse[:classes].each_with_index do |c, index|
          next if index == 0
          c_pref_lab = get_closest_preflab(c.prefLabel)
          c_id = c.id
          c_ui_link = c.links['ui']
          c_end_point = get_after_last_slash(c_ui_link)
          c_link = "/ontologies/#{c_end_point}"
          c_definition = get_element_defintion(c.definition)
          reuse_decendents_list_element = {preflab: c_pref_lab, id: c_id, link: c_link, definition: c_definition}
          reuse_decendents_list.push(reuse_decendents_list_element)
        end
        reuses_list_element[:decendants] = reuse_decendents_list
        reuses.push(reuses_list_element)
      end
      
      search_result_element = {
        title: { preflab: element_pref_lab, ontology: element_ontology_name_acronym, id: element_id, link: element_link, definition: element_definition},
        descendants: decendents,
        reuses: reuses
      }

      search_results.push(search_result_element)
    end
    #binding.pry
    return search_results
  end

  def get_ontology_name_acronym_by_uri(element_ontology)
    element_ontology_info = LinkedData::Client::Models::Ontology.find(element_ontology)
    element_ontology_name = element_ontology_info.name
    element_ontology_acronym = element_ontology_info.acronym
    element_ontology_name_acronym = "#{element_ontology_name} (#{element_ontology_acronym})"
    return element_ontology_name_acronym
  end

  def get_after_last_slash(input_string)
    segments = input_string.split('/')
    result = segments.last
    return result
  end

  def get_element_defintion(definitions_array)
    result = ""
    unless definitions_array.eql?(nil)
      definitions_array.each do |defintion|
        result = "#{result} #{defintion}. "
      end
    end
    result
  end

  def get_closest_preflab(preflabs_list)
    selected = preflabs_list.select do |pref_lab| 
        pref_lab.include?(@search_query) || @search_query.include?(pref_lab) 
    end.first  

    selected || preflabs_list&.first 
  end

  def define_search_api_params(params)
    @language = params[:search_language]
    selected_ontologies_string = params[:ontologies_list]&.join(',')
    selected_categories_string = params[:categories_list]&.join(',')
    @exact_matches = params["exact-matches"].eql?(nil) ? "false" : "true"
    @require_definition = params["classes-with-definitions"].eql?(nil) ? "false" : "true"
    @property_values = params['property-values'].eql?(nil) ? "false" : "true"
    @obsolete_classes = params['obsolete-classes'].eql?(nil) ? "false" : "true"
    @ontology_views = params['ontology-views'].eql?(nil) ? "false" : "true"
    params[:lang] = @language
    params[:categories] = selected_categories_string
    params[:ontologies] = selected_ontologies_string
    params[:require_definition] = @require_definition
    params[:exact_match] = @exact_matches
    params[:include_views] = @ontology_views
    params[:obsolete] = @obsolete_classes
    params[:include_properties] = @property_values
  end

  def params_empty?(params)
    return (params[:search_language].eql?('all') || params[:search_language].eql?(nil))   && params[:ontologies_list].eql?(nil) && params[:categories_list].eql?(nil) && params["exact-matches"].eql?(nil) && params["classes-with-definitions"].eql?(nil) && params['property-values'].eql?(nil) && params['obsolete-classes'].eql?(nil) && params['ontology-views'].eql?(nil)
  end

  def add_reuses_to_structure(grouped_results)
    transformed_structure = {}

    grouped_results.each do |ontology_id, classes|
      transformed_structure[ontology_id] = {
        classes: classes,
        reuses: []  
      }
    end

    return transformed_structure
  end

  def add_ontology_reuses(data)
    data.each do |ontology_id, ontology|
      ontology_classes = ontology[:classes]
  
      data.each do |other_ontology_id, other_ontology|
        next if ontology_id == other_ontology_id
  
        other_classes = other_ontology[:classes]
        common_ids = ontology_classes.map { |c| c[:id] } & other_classes.map { |c| c[:id] }
  
        unless common_ids.empty?
          embedded_ontology = {
            id: other_ontology_id,
            classes: other_ontology[:classes]
          }
  
          ontology[:reuses] << embedded_ontology
          data.delete(other_ontology_id)
        end
      end
    end
    return data
  end
