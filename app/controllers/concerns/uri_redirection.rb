# frozen_string_literal: true

module UriRedirection
  extend ActiveSupport::Concern

  include SearchContent

  def find_type_by_id(id, acronym)
    type, resource_id = find_type_by_search(id, acronym)
    return type, resource_id if type

    type, resource_id = find_type_by_metadata(id, acronym)
    return type, resource_id if type

    return nil, nil
  end


  def redirect_to_file?
    accept_header.nil? || (accept_header != "text/html" && params[:p].nil?)
  end

  def redirect_to_file
    # check for hasOntologySyntax field for turtle format
    ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    ontology_syntax = ontology.explore.latest_submission(include: 'hasOntologySyntax').hasOntologySyntax

    return not_acceptable("Invalid requested format, valid format are: HTML, JSON, XML, CSV.\nNTriples and Turtle format is available for some resources\nYou can download the original file you can get it from: #{rest_url}/ontologies/#{params[:id]}/download\n") if accept_header.nil? || (ontology_syntax != "http://www.w3.org/ns/formats/Turtle" && accept_header== "text/turtle") || (ontology_syntax != "http://www.w3.org/ns/formats/N-Triples" && accept_header== "application/ntriples")
    
    # when the format is different than text/html
    download_ontology(acronym: params[:id], format: accept_header) if (accept_header != "text/html" && params[:p].nil?)
  end

  def download_ontology(params)
    redirect_url = "#{rest_url}/ontologies/#{params[:acronym]}"
    download_url = "#{redirect_url}/download?apikey=#{get_apikey}"
    case params[:format]
    when 'text/csv', 'csv'
        fetch_and_forward_data("#{download_url}&download_format=csv")
    when 'text/xml', 'text/rdf+xml', 'application/rdf+xml', 'application/xml', 'xml'
        fetch_and_forward_data("#{download_url}&download_format=rdf")
    when 'application/json', 'application/ld+json', 'application/*', 'json'
        fetch_and_forward_data("#{redirect_url}?apikey=#{get_apikey}")
    else
        fetch_and_forward_data(download_url)
    end
  end

  private

  def find_type_by_search(id, acronym)
    # search for URIs that ends with "/id" or "#id"
    result = search_content(q: "*##{id} || *\/#{id}", qf: "resource_id", page: 1, pagesize: 10, ontologies: acronym)

    find_exact_resource = result[:collection].select { |x| helpers.link_last_part(x[:resource_id]).eql?(id) }.first

    if !find_exact_resource
      type = nil
      resource_id = nil
    else
      type = id_type(find_exact_resource[:type_t], find_exact_resource[:type_txt])
      resource_id = find_exact_resource[:resource_id]
    end

    [type, resource_id]
  end

  def find_type_by_metadata(id, acronym)
    return nil, nil # TODO maybe implemented if needed
  end


  def not_acceptable(message = nil)
    render plain: message, status: 406
  end

  def fetch_and_forward_data(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    send_data response.body, type: response.content_type, status: response.code.to_i
  end


  def accept_header
    header = request.env["HTTP_ACCEPT"]
    entries = header.to_s.split(',')
    parsed_entries = entries.map { |e| accept_entry(e) }
    sorted_entries = parsed_entries.sort_by(&:last)
    content_types = sorted_entries.map(&:first)
    filtered_content_types = content_types.map { |e| find_content_type_for_media_range(e) }
    filtered_content_types.flatten.compact.first
  end

  def accept_entry(entry)
    type, *options = entry.split(';').map(&:strip)
    quality = 0
    options.delete_if { |e| quality = 1 - e[2..-1].to_f if e.start_with? 'q=' }
    [options.unshift(type).join(';'), [quality, type.count('*'), 1 - options.size]]
  end

  def find_content_type_for_media_range(media_range)
    case media_range.to_s
    when '*/*', 'text/html', 'text/*'
      'text/html'
    when 'application/json', 'application/ld+json', 'application/*'
      'application/ld+json'
    when 'text/xml', 'text/rdf+xml', 'application/rdf+xml', 'application/xml'
      'application/rdf+xml'
    when 'application/ntriples', 'application/n-triples'
      'application/ntriples'
    when 'text/csv'
      'text/csv'
    when 'text/turtle'
      'text/turtle'
    else
      nil
    end
  end

end