module SparqlHelper
  def change_from_clause(query, graph)
    unless graph.blank?
      graph = graph.gsub($REST_URL, 'http://data.bioontology.org')

      query.gsub!(/WHERE/i, "FROM <#{graph}> WHERE")

      # Use a regular expression to replace all instances of FROM <uri>
      # Will change any FROM "anything" or GRAPH "anything" and transform it to FROM <a secure graph uri> or GRAPH <a secure graph uri>
      query.gsub!(/FROM\s+\S+/i, "FROM <#{graph}>")
      query.gsub!(/GRAPH\s+\S+/i, "GRAPH <#{graph}>")

      # If there's no WHERE but there's a closing brace,
      if !query.match?(/WHERE/i) && query.include?("{") && query.include?("}")
        last_brace_index = query.index("{")
        query = query[0..last_brace_index-1] + " FROM <#{graph}> " + query[last_brace_index..-1]
      end

    end

    query
  end
  def ontology_sparql_query(query, graph = '')
    query = change_from_clause(query, graph)
    sparql_query(query)
  end
  def is_allowed_query?(sparql_query)
    forbidden_operations = [
      'INSERT DATA',
      'DELETE DATA',
      'DELETE/INSERT',
      'DELETE',
      'INSERT',
      'DELETE WHERE',
      'LOAD',
      'CLEAR',
      'CREATE',
      'DROP',
      'COPY',
      'MOVE',
      'ADD'
    ]

    # Define a regular expression to match SELECT queries
    select_query_regex = /\A\s*SELECT\b/m

    # Check if the query contains any forbidden operations outside SELECT queries
    return false if forbidden_operations.any? { |op| sparql_query.upcase.include?(op) && !sparql_query.match(select_query_regex) }

    true
  end

  def sparql_query(query)
    return 'No SPARQL endpoint configured' if $SPARQL_URL.blank?
    return 'INSERT Queries not permitted' unless  is_allowed_query?(query)
    endpoint = $SPARQL_URL.gsub('test', 'sparql')
    begin
      conn = Faraday.new do |conn|
        conn.options.timeout = 60
      end
      response = conn.get("#{endpoint}?query=#{encode_param(query)}")
      response.body.force_encoding('ISO-8859-1').encode('UTF-8')
    rescue
      "Query timeout"
    end
  end
  def sparql_query_container(username: current_user&.username, graph: nil, apikey: get_apikey)
    content_tag(:div, '', data: {controller: 'sparql',
                                 'sparql-proxy-value': '/sparql_proxy/',
                                 'sparql-apikey-value': apikey,
                                 'sparql-username-value': username,
                                 'sparql-graph-value': graph})
  end

end
