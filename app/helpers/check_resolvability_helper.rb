module CheckResolvabilityHelper

  def resolvability_formats
    %w[application/rdf+xml application/xml text/turtle application/ld+json application/json text/n3 text/html application/xhtml+xml text/plain]
  end

  def resolvability_timeout
    30
  end

  def resolvability_max_redirections
    10
  end

  def check_resolvability_helper(url, negotiation_formats = resolvability_formats, timeout_seconds = resolvability_timeout)
    redirections = []
    returned_formats = []
    begin
      uri = URI.parse(url)
      redirections << uri
      # Follow redirects
      response = nil
      redirect_limit = resolvability_max_redirections # Set a limit to prevent infinite loops
      redirect_count = 0
      until (!response.nil? && !response.is_a?(Net::HTTPRedirection)) || redirect_count >= redirect_limit
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = timeout_seconds
        response = Timeout.timeout(timeout_seconds) { http.request_head(uri.path) }
        if response.is_a?(Net::HTTPRedirection)
          if uri.to_s.include?(response['location'].chomp('/'))
            uri = URI.parse(uri.scheme + '://' + uri.host + '/' + response['location'])
          else
            uri = URI.parse(response['location'])
          end
          redirections << uri
          redirect_count += 1
        end
      end

      # Check if the final response indicates successful dereferencing
      if response && response.is_a?(Net::HTTPSuccess)
        # Check if content negotiation is supported for any of the formats
        supported_format = negotiation_formats.find_all do |format|
          begin
            test_response = Timeout.timeout(timeout_seconds) do
              http.head(uri.path, 'Accept' => format)
            end
            returned_formats << test_response.content_type if test_response.is_a?(Net::HTTPSuccess)
            test_response.is_a?(Net::HTTPSuccess) && test_response.content_type.include?(format)
          rescue
            false
          end
        end

        if supported_format.size > 1
          return { result: 2, status: response.code, allowed_format: supported_format, returned_formats: returned_formats, redirections: redirections }
        else
          return { result: 1, status: response.code, allowed_format: Array(supported_format), returned_formats: returned_formats, redirections: redirections }
        end
      else
        return { result: 0, status: response ? response.code : nil, allowed_format: [], returned_formats: returned_formats, redirections: redirections }
      end
    rescue Timeout::Error || Net::OpenTimeout
      return { result: 0, status: 'Timeout', allowed_format: [], returned_formats: returned_formats, redirections: redirections }
    rescue StandardError => e
      return { result: 0, status: e.message, allowed_format: [], returned_formats: returned_formats, redirections: redirections }
    end
  end

  def url_resolvable?(result)
    result[:result].eql?(1) || url_content_negotiable?(result)
  end

  def url_content_negotiable?(result)
    result[:result].eql?(2)
  end

  def check_resolvability_success(result)
    url_resolvable?(result) || url_content_negotiable?(result)
  end

  def check_resolvability_message(resolvable, allowed_formats, status)
    if resolvable && (Array(allowed_formats).size > 1)
      "The URL is resolvable and support the following formats: #{allowed_formats.join(', ')}"
    elsif resolvable
      "The URL resolvable but is not content negotiable, support only: #{allowed_formats.join(', ')}"
    else
      "The URL is not resolvable and not content negotiable (returns #{status})."
    end
  end
end
