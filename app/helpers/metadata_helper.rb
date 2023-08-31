module MetadataHelper

  def input_type?(attr, type)
    attr['enforce'].include?(type)
  end

  def submission_metadata
    @metadata ||= JSON.parse(Net::HTTP.get(URI.parse("#{$REST_URL}/submission_metadata?apikey=#{$API_KEY}")))
  end

  # @param attr_key string
  def attr_metadata(attr_key)
    submission_metadata.select { |attr_hash| attr_hash['attribute'].to_s.eql?(attr_key) }.first
  end


  def integer?(attr_label)
    input_type?(attr_metadata(attr_label), 'integer')
  end

  def date_time?(attr_label)
    input_type?(attr_metadata(attr_label), 'date_time')
  end

  def textarea?(attr_label)
    input_type?(attr_metadata(attr_label), 'textarea')
  end

  def enforce_values?(attr)
    !attr['enforcedValues'].nil?
  end

  def list?(attr_label)
    input_type?(attr_metadata(attr_label), 'list')
  end

  def is_ontology?(attr_label)
    input_type?(attr_metadata(attr_label), 'isOntology')
  end

  def attr_uri?(attr_label)
    input_type?(attr_metadata(attr_label), 'uri')
  end

  def boolean?(attr_label)
    input_type?(attr_metadata(attr_label), 'boolean')
  end

  def agent?(attr)
    input_type?(attr_metadata(attr), 'Agent')
  end

end