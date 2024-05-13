module CheckResolvabilityHelper

  def formats_equivalents(format = nil)
    all = {
      'application/json' => ['application/ld+json'],
      'application/rdf+xml' => %w[application/xml application/rdf+xml text/xml application/octet-stream],
      'text/turtle' => ['application/turtle'],
      'text/n3' => ['application/n-triples'],
      'text/html' => []
    }

    return all unless format

    all[format]
  end

  def resolvability_formats
    formats_equivalents.keys
  end

  def resolvability_timeout
    5
  end

  def resolvability_max_redirections
    10
  end

  def resolvability_status(status, allowed_format, redirections, result: nil)

    supported_format = Array(allowed_format)
    unless result
      supported_format += redirections.map { |k, v| v[:status].to_s.eql?('200') && v[:allowed_format] }.compact
      supported_format.uniq!
      if supported_format.size > 1
        result = 2 # negotiable
      elsif !supported_format.empty?
        result = 1 # resolvable
      end
    end

    { result: result, status: status, allowed_format: supported_format, redirections: redirections }
  end

  def follow_redirection(url, format, timeout_seconds, redirect_limit = resolvability_max_redirections)
    url = url.strip
    uri = URI.parse(url)
    response = nil
    redirect_count = 0
    redirections = [uri]

    until (!response.nil? && !response.is_a?(Net::HTTPRedirection)) || redirect_count >= redirect_limit
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = timeout_seconds
      begin
        response = Timeout.timeout(timeout_seconds) { http.request_head(uri, 'Accept' => format) }
      rescue Timeout::Error, Net::OpenTimeout
        return resolvability_status('Timeout', [], redirections, result: 0)
      end

      if response.is_a?(Net::HTTPRedirection) && response['location']
        if !uri.to_s.start_with?(response['location']) && uri.to_s.include?(response['location'].chomp('/'))
          uri = URI.parse(uri.scheme + '://' + uri.host + '/' + response['location'])
        else
          uri = URI.parse(response['location'])
        end
        redirections << uri
        redirect_count += 1
      end
    end

    if response&.code.to_s.eql?('200') && (response&.content_type.to_s.include?(format) || formats_equivalents(format)&.include?(response&.content_type.to_s))
      result = 2
    elsif response&.code.to_s.eql?('200')
      result = 1
    else
      result = 0
    end
    resolvability_status(response&.code, [response&.content_type], redirections, result: result)
  end

  def check_resolvability_helper(url, negotiation_formats = resolvability_formats, timeout_seconds = resolvability_timeout)
    redirections = {}
    supported_format = negotiation_formats.find_all do |format|
      begin
        redirections[format] = follow_redirection(url, format, timeout_seconds)
        redirections[:result].eql?(2)
      rescue StandardError => e
        redirections[format] = resolvability_status(e.message, [], [], result: 0)
        false
      end
    end

    status = redirections.values.map { |v| v[:status] }.uniq.join(', ')
    if supported_format.size > 1
      { result: 2, status: status, allowed_format: supported_format, redirections: redirections }
    elsif status.include?('200')
      returned_format = redirections.map { |k, v| !v[:result].eql?(0) ? v[:allowed_format] : nil }.flatten.compact.uniq
      { result: 1, status: status, allowed_format: returned_format, redirections: redirections }
    else
      { result: 0, status: status, allowed_format: [], redirections: redirections }
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

  def check_resolvability_message(resolvable, allowed_formats, status, url = nil)
    supported_format = Array(allowed_formats).compact
    supported_format = allowed_formats.empty? ? 'Format not specified' : supported_format.join(', ')

    if resolvable && (supported_format.size > 1)
      text = t('check_resolvability.check_resolvability_message_1', supported_format: supported_format)
    elsif resolvable
      text = t('check_resolvability.check_resolvability_message_2', supported_format: supported_format)
    else
      text = t('check_resolvability.check_resolvability_message_3', status: status)
    end


    text = text + link_to(', click to see details', check_resolvability_path(url: url), target: '_blank') if url
    text
  end
end
