module SparqlHelper
  def change_from_clause(query, graph)
    unless graph.blank?
      graph = graph.gsub($REST_URL, 'http://data.bioontology.org')

      if query.match?(/FROM <[^>]+>/i)
        # Use a regular expression to replace all instances of FROM <uri>
        query = query.gsub(/FROM <[^>]+>/i, "")
      else
        query = query.gsub("WHERE", "FROM <#{graph}> WHERE")
      end

      query = query.gsub(/GRAPH <[^>]+>/i, "")
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
  def sparql_query_container(graph: nil)
    content_tag(:div, '', data: {controller: 'sparql',
                                 'sparql-proxy-value': '/sparql_proxy/',
                                 'sparql-graph-value': graph})
  end

end
