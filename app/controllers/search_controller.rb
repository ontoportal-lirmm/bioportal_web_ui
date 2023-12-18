require 'uri'

class SearchController < ApplicationController

  skip_before_action :verify_authenticity_token

  layout :determine_layout

  def index
    @search_query = params[:query].nil? ? params[:q] : params[:query]
    params[:q] = params[:query]
    params[:query] = nil
    @search_query ||= ""
    
    unless @search_query.eql?("")
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
    grouped_results.each_key do |key|
      element_pref_lab = grouped_results[key][0].prefLabel[0]
      element_id = grouped_results[key][0].id
      element_ontology_uri = grouped_results[key][0].links['ontology']
      element_ontology_name_acronym = get_ontology_name_acronym_by_uri(element_ontology_uri)
      ui_link = grouped_results[key][0].links['ui']
      end_point = get_after_last_slash(ui_link)
      element_link = "/ontologies/#{end_point}"
      
      element_definition = get_element_defintion(grouped_results[key][0].definition) 
      
      
      
      decendents = []
      grouped_results[key].each_with_index do |e , index|
        next if index == 0
        e_pref_lab = e.prefLabel[0]
        e_id = e.id
        e_ui_link = e.links['ui']
        e_definition = get_element_defintion(e.definition)
        e_end_point = get_after_last_slash(e_ui_link)
        e_link = "/ontologies/#{e_end_point}"
        decendents_list_element = {preflab: e_pref_lab,id: e_id, link: e_link, definition: e_definition}
        decendents.push(decendents_list_element)
      end
      
      search_result_element = {
        title: { preflab: element_pref_lab, ontology: element_ontology_name_acronym, id: element_id, link: element_link, definition: element_definition},
        descendants: decendents
      }

      search_results.push(search_result_element)
    end
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
