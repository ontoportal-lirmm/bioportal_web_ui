module MetadataHelper

  def input_type?(attr, type)
    attr["enforce"].include?(type)
  end

  def attr_metadata(attr_key)
    submission_metadata.select { |attr_hash| attr_hash["attribute"].to_s.eql?(attr_key) }.first
  end

  def attr_label(attr)
    data = attr_metadata(attr.to_s)
    return attr.humanize if data.nil?
    data["label"]
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
    !attr["enforcedValues"].nil?
  end

  def list?(attr_label)
    input_type?(attr_metadata(attr_label), "list")
  end

  def isOntology?(attr_label)
    input_type?(attr_metadata(attr_label), 'isOntology')
  end

  def attr_uri?(attr_label)
    input_type?(attr_metadata(attr_label), "uri")
  end

  def boolean?(attr_label)
    input_type?(attr_metadata(attr_label), "boolean")
  end

  def agent?(attr)
    input_type?(attr_metadata(attr), "Agent")
  end

  def display_attribute(metadata, value)
    return 'N/A' if value.nil? || Array(value).empty?

    if agent?(metadata)
      display_agent(value)
    elsif metadata.eql?("naturalLanguage")
      render LanguageFieldComponent.new(value: value)
    elsif metadata.to_s.eql?("hasLicense")
      render LicenseFieldComponent.new(value: value)
    elsif metadata.to_s.eql?("endpoint") && (value.start_with?("http://sparql.") || value.start_with?("https://sparql."))
      link_to(value, :title => value, :target => "_blank", :style => "border-width:0;") do
        image_tag('logos/sparql_logo.png', :title => value, :class => 'logo')
      end
    elsif date_time?(metadata)
      render DateTimeFieldComponent.new(value: value)
    elsif attr_uri?(metadata)
      render LinkFieldComponent.new(value: value)
    elsif input_type?(attr_metadata(metadata), 'contact')
      display_contact(value)
    else
      render TextAreaFieldComponent.new(value: value.to_s)
    end
  end

end