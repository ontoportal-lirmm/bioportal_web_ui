require 'sparql/grammar'
module SparqlHelper
  def change_from_clause(query, graph)
    validate_sparql_query(query)
    query = remove_sparql_comments(query)
    # Clean up any blank lines that might have been created
    query.gsub!(/\n\s*\n+/, "\n")

    unless graph.blank?
      graph = graph.gsub($REST_URL, 'http://data.bioontology.org')

      if query.match?(/(?<=\s|^)FROM\s*\S+[^{ \n]/i)
        #  match FROM <URI> and FROM meta:User (only after space or start of line)
        query.gsub!(/(?<=\s|^)FROM\s*\S+[^{ \n]/i, "FROM <#{graph}>")
      elsif query.match?(/WHERE\s+\S+/i)
        # match WHERE without FROM
        query.gsub!(/WHERE/i, "FROM <#{graph}> WHERE")
      end
      # match GRAPH <URI> and GRAPH meta:User (only after space or start of line)
      query.gsub!(/(?<=\s|^)GRAPH\s*[^\{]+\{/i, "GRAPH <#{graph}> {")

      # match SELECT without FROM and WHERE and ignore the { inside quotes
      if query.match?(/(SELECT.*?\s*\S*)(?<!["'\s])\s*\{(?![^"]*["'])/im)
        query.sub!(/(SELECT.*?\s*\S*)(?<!["'\s])\s*\{(?![^"]*["'])/im) do |match|
          if match.downcase.match?(/(?<!["'(\s])\s*FROM(?![^"]*["')])/i)
            match
          else
            out = "#{$1}"
            out = out.gsub(/WHERE/i, '') if out.downcase.include?('where')
            "#{out.strip} FROM <#{graph}> WHERE {"
          end
        end
      end
    end

    validate_sparql_query(query)
    query
  end

  def ontology_sparql_query(query, graph = '')
    query = change_from_clause(query, graph)
    sparql_query(query)
  rescue StandardError
    'Failed to parse query'
  end

  def sparql_query(query)
    return 'No SPARQL endpoint configured' if $SPARQL_URL.blank?
    return 'INSERT Queries not permitted' unless is_allowed_query?(query)

    endpoint = $SPARQL_URL.gsub('test', 'sparql')
    begin
      conn = Faraday.new do |conn|
        conn.options.timeout = 10
      end
      response = conn.get("#{endpoint}?query=#{encode_param(query)}")
      response.body.force_encoding('ISO-8859-1').encode('UTF-8')
    rescue StandardError
      'Query timeout'
    end
  end

  def sparql_query_container(username: current_user&.username, graph: nil, apikey: get_apikey)
    content_tag(:div, '', data: { controller: 'sparql',
                                  'sparql-proxy-value': '/sparql_proxy/',
                                  'sparql-apikey-value': apikey,
                                  'sparql-username-value': username,
                                  'sparql-graph-value': graph })
  end

  private

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
    if forbidden_operations.any? { |op| sparql_query.upcase.include?(op) && !sparql_query.match(select_query_regex) }
      return false
    end

    true
  end

  def remove_sparql_comments(query)
    # Remove everything from # to end of line, unless the # is inside angle brackets
    lines = query.split("\n")
    cleaned_lines = lines.map do |line|
      inside_uri = false
      comment_start = nil

      line.each_char.with_index do |char, i|
        if char == '<'
          inside_uri = true
        elsif char == '>'
          inside_uri = false
        elsif char == '#' && !inside_uri
          comment_start = i
          break
        end
      end

      comment_start ? line[0...comment_start] : line
    end

    cleaned_lines.join("\n")
  end

  def validate_sparql_query(query)
    SPARQL::Grammar.parse(query)
  rescue StandardError => e
    raise StandardError, "Failed to parse query: #{e.message}"
  end

end
