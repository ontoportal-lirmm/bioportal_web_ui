module SubmissionsHelper
  def extractable_metadatum_tooltip(options = {})
    help_tooltip(options[:content], {}, "fas fa-file-export", "extractable-metadatum", options[:text]).html_safe
  end

  def attribute_infos(attr_label)
    @metadata.select { |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first
  end

  def attribute_help_text(attr)
    if !attr["namespace"].nil?
      help_text = "&lt;strong&gt;#{attr["namespace"]}:#{attr["attribute"]}&lt;/strong&gt;"
    else
      help_text = "&lt;strong&gt;bioportal:#{attr["attribute"]}&lt;/strong&gt;"
    end

    if (attr["metadataMappings"] != nil)
      help_text << " (#{attr["metadataMappings"].join(", ")})"
    end

    if (!attr["enforce"].nil? && attr["enforce"].include?("uri"))
      help_text << "&lt;br&gt;This metadata should be an &lt;strong&gt;URI&lt;/strong&gt;"
    end

    if (attr["helpText"] != nil)
      help_text << "&lt;br&gt;&lt;br&gt;#{attr["helpText"]}"
    end
    help_text
  end

  # Generate the HTML label for every attributes
  def generate_attribute_label(attr_label)
    # Get the attribute hash corresponding to the given attribute
    attr = attribute_infos(attr_label)
    label_html = if !attr["extracted"].nil? && attr["extracted"] == true
      extractable_metadatum_tooltip({ content: "Extractable metadatum" })
    end.to_s.html_safe

    if !attr["label"].nil?
      label_html << label_tag("submission_#{attr_label}", attr["label"], { class: "form-label" })
    else
      label_html << label_tag("submission_#{attr_label}", attr_label.underscore.humanize, { class: "form-label" })
    end

    # Generate tooltip
    help_text = attribute_help_text(attr)
    label_html << help_tooltip(help_text, { :id => "tooltip#{attr["attribute"]}" }).html_safe
    label_html
  end

  # Generate the HTML input for every attributes.
  def generate_attribute_input(attr_label, options = {})
    input_html = "".html_safe

    # Get the attribute hash corresponding to the given attribute
    attr = @metadata.select { |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first

    if attr["enforce"].include?("integer")
      number_field :submission, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"]), class: "metadataInput form-control"
    elsif attr["enforce"].include?("date_time")
      field_id = [:submission, attr["attribute"].to_s].join("_")
      date_value = @submission.send(attr["attribute"]).presence
      date_value &&= Date.parse(date_value)
      date_value ||= options[:default]
      date_value &&= l(date_value, format: :month_day_year)

      content_tag(:div, class: "input-group") do
        [
          text_field(:submission, attr["attribute"].to_s.to_sym, value: date_value, id: field_id, class: "form-control datepicker"),
          content_tag(:div, class: "input-group-append") do
            content_tag(:span, class: "input-group-text datepicker-btn", onclick: "$('##{field_id}').datepicker('show')") do
              content_tag(:i, "", class: "fas fa-calendar-alt fa-l")
            end
          end,
        ].join.html_safe
      end
    elsif attr["enforce"].include?("textarea")
      text_area(:submission, attr["attribute"].to_s.to_sym, rows: 3, value: @submission.send(attr["attribute"]), class: "metadataInput form-control")

      # Create select dropdown when there are enforcedValues for the attr. But also let the user enter its own value if Other selected
    elsif !attr["enforcedValues"].nil?
      metadata_values = @submission.send(attr["attribute"])
      select_values = attr["enforcedValues"].collect { |k, v| [v, k] }
      # Add in the select ontologies that are not in the portal but are in the values
      if metadata_values.kind_of?(Array)
        metadata_values.map do |metadata|
          if !select_values.flatten.include?(metadata)
            select_values << metadata
          end
        end
      else
        if (!select_values.flatten.include?(metadata_values) && !metadata_values.to_s.empty?)
          select_values << metadata_values
        end
      end

      if attr["enforce"].include?("list")
        input_html << select_tag("submission[#{attr_label}][]", options_for_select(select_values, metadata_values), :multiple => "true",
                                                                                                                    "data-placeholder".to_sym => "Select ontologies", :style => "margin-bottom: 15px; width: 100%;", :id => "select_#{attr["attribute"]}", :class => "selectOntology")

        input_html << text_field_tag("add_#{attr["attribute"].to_s}", nil, :style => "margin-right: 1em;width: 16em;", :placeholder => "Or provide the value",
                                                                           :onkeydown => "if (event.keyCode == 13) { addOntoToSelect('#{attr["attribute"]}'); return false;}", :class => "metadataInput form-control")

        input_html << button_tag("Add new value", :id => "btnAdd#{attr["attribute"]}",
                                                  :type => "button", :class => "btn btn-primary btn-sm add-value-btn", :onclick => "addOntoToSelect('#{attr["attribute"]}')")
      else
        select_values << ["None", ""]
        select_values << ["Other", "other"]

        if metadata_values.nil?
          metadata_values = ""
        end

        input_html << select("submission", attr["attribute"], select_values, { :selected => metadata_values }, { :class => "form-control", :id => "select_#{attr["attribute"]}", :style => "margin-bottom: 1em;" })

        # Button and field to add new value (that are not in the select). Show when other is selected
        input_html << text_field_tag("add_#{attr["attribute"].to_s}", nil, :style => "margin-right: 1em;width: 16em;display: none;", :placeholder => "Or provide the value",
                                                                           :onkeydown => "if (event.keyCode == 13) { addValueToSelect('#{attr["attribute"]}'); return false;}", :class => "metadataInput form-control")

        input_html << button_tag("Add new value", :id => "btnAdd#{attr["attribute"]}",
                                                  :type => "button", :class => "btn btn-primary btn-sm add-value-btn", :onclick => "addValueToSelect('#{attr["attribute"]}')")

        # To show/hide textbox when other option is selected or not
        input_html << javascript_tag("$(document).ready(function() {
            $('#select_#{attr["attribute"]}').change(function() {
              toggleOtherValue('#{attr["attribute"].to_s}');
            });
            toggleOtherValue('#{attr["attribute"].to_s}');
          })")
      end

      return input_html
    elsif attr["enforce"].include?("isOntology")
      metadata_values = @submission.send(attr["attribute"])
      select_values = ontologies_for_select.dup
      # Add in the select ontologies that are not in the portal but are in the values
      if metadata_values.kind_of?(Array)
        metadata_values.map do |metadata|
          if !select_values.flatten.include?(metadata)
            select_values << metadata
          end
        end
      else
        if !select_values.flatten.include?(metadata_values)
          select_values << metadata_values
        end
      end

      if attr["enforce"].include?("list")
        input_html << select_tag("submission[#{attr_label}][]", options_for_select(select_values, metadata_values), :multiple => "true",
                                                                                                                    "data-placeholder".to_sym => "Select ontologies", :style => "margin-bottom: 15px; width: 100%;", :id => "select_#{attr["attribute"]}", :class => "selectOntology")
      else
        input_html << select_tag("submission[#{attr_label}]", options_for_select(select_values, metadata_values), "data-placeholder".to_sym => "Select ontology",
                                                                                                                  :style => "margin-bottom: 15px; width: 100%;", :id => "select_#{attr["attribute"]}", :class => "selectOntology", :include_blank => true)
      end
      # Button and field to add new value (not in the select)
      input_html << tag(:br)

      input_html << text_field_tag("add_#{attr["attribute"]}", nil, :style => "margin-right: 1em;vertical-align: super;width: 16em; display: inline",
                                                                    :placeholder => "Ontology outside of the Portal", :onkeydown => "if (event.keyCode == 13) { addOntoToSelect('#{attr["attribute"]}'); return false;}", :class => "metadataInput form-control")

      input_html << button_tag("Add new ontology", :id => "btnAdd#{attr["attribute"]}", :style => "margin-bottom: 2em;margin-top: 1em;",
                                                   :type => "button", :class => "btn btn-primary btn-sm", :onclick => "addOntoToSelect('#{attr["attribute"]}')")

      return input_html
    elsif attr["enforce"].include?("uri")
      if @submission.send(attr["attribute"]).nil?
        uri_value = ""
      else
        uri_value = @submission.send(attr["attribute"])
      end

      if attr["enforce"].include?("list")
        input_html << button_tag("Add new value", :id => "add#{attr["attribute"]}",
                                                  :type => "button", :class => "btn btn-primary btn-sm add-value-btn", :onclick => "addInput('#{attr["attribute"]}', 'url')")
        input_html << url_field_tag("submission[#{attr["attribute"].to_s}][]", uri_value[0], :id => attr["attribute"].to_s, class: "metadataInput form-control")
        # Add field if list of URI
        if !@submission.send(attr["attribute"]).nil? && @submission.send(attr["attribute"]).any?
          @submission.send(attr["attribute"]).each_with_index do |metadata_val, index|
            if index != 0
              input_html << url_field_tag("submission[#{attr["attribute"].to_s}][]", metadata_val, :id => "submission_#{attr["attribute"].to_s}", class: "metadataInput form-control")
            end
          end
        end
        input_html << content_tag(:div, "", id: "#{attr["attribute"]}Div")
      else
        # if single value
        input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: uri_value, class: "metadataInput form-control")
      end
      return input_html
    elsif attr["enforce"].include?("boolean")
      select("submission", attr["attribute"].to_s, ["none", "true", "false"], { :selected => @submission.send(attr["attribute"]) },
             { :class => "form-control", :style => "margin-top: 0.5em; margin-bottom: 0.5em;" })
    else
      # If input a simple text

      if attr["enforce"].include?("list")
        input_html << button_tag("Add new value", :id => "add#{attr["attribute"]}",
                                                  :type => "button", :class => "btn btn-primary btn-sm add-value-btn", :onclick => "addInput('#{attr["attribute"]}', 'text')")
        firstVal = ""
        if !@submission.send(attr["attribute"]).nil? && @submission.send(attr["attribute"]).any?
          firstVal = @submission.send(attr["attribute"])[0]
        end
        input_html << text_field_tag("submission[#{attr["attribute"].to_s}][]", firstVal, :id => attr["attribute"].to_s, class: "metadataInput form-control")

        # Add field if list of metadata
        if !@submission.send(attr["attribute"]).nil? && @submission.send(attr["attribute"]).any?
          @submission.send(attr["attribute"]).each_with_index do |metadata_val, index|
            if index != 0
              input_html << text_field_tag("submission[#{attr["attribute"].to_s}][]", metadata_val, :id => "submission_#{attr["attribute"].to_s}", class: "metadataInput form-control")
            end
          end
        end

        input_html << content_tag(:div, "", id: "#{attr["attribute"]}Div")
      else
        # if single value text
        # TODO: For some reason @submission.send("URI") FAILS... I don't know why... so I need to call it manually
        if attr["attribute"].to_s.eql?("URI")
          input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: @submission.URI, class: "metadataInput form-control")
        else
          input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"]), class: "metadataInput form-control")
        end
      end
      return input_html
    end
  end

  def generate_attribute_text(attr_label, label)
    attr = attribute_infos(attr_label)
    label_html = "<div class='d-flex align-items-center'><span class='mr-1'>#{label}</span><span>"
    # Generate tooltip
    help_text = attribute_help_text(attr)
    label_html << help_tooltip(help_text, { :id => "tooltip#{attr["attribute"]}" }).html_safe
    label_html << "</span></div>"
    label_html.html_safe
  end

  def ontologies_for_select
    @ontologies_for_select ||= LinkedData::Client::Models::Ontology.all.collect do |onto|
      ["#{onto.name} (#{onto.acronym})", onto.id]
    end
  end
end
