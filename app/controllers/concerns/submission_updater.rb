module SubmissionUpdater
  extend ActiveSupport::Concern

  def save_submission(new_submission_hash)
    convert_values_to_types(new_submission_hash)

    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(new_submission_hash[:ontology]).first
    @submission = LinkedData::Client::Models::OntologySubmission.new(values: submission_params(new_submission_hash))

    update_ontology_summary_only
    @submission.save(cache_refresh_all: false)
  end

  def update_submission(new_submission_hash)

    convert_values_to_types(new_submission_hash)

    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(new_submission_hash[:ontology]).first
    @submission = @ontology.explore.submissions({ display: 'all' }, new_submission_hash[:id])

    @submission.update_from_params(submission_params(new_submission_hash))

    update_ontology_summary_only
    @submission.update(cache_refresh_all: false)
  end

  def add_ontologies_to_object(ontologies,object)
    ontologies.each do |ont|
      next if object.ontologies.include?(ont)
        ontology = LinkedData::Client::Models::Ontology.find(ont)
        if object.type.match(/\/([^\/]+)$/)[1] == 'Group'
          ontology.group.push(object.id)
        else 
          ontology.hasDomain.push(object.id)
        end
        ontology.update
    end
  end

  def delete_ontologies_from_object(new_ontologies,old_ontologies,object)
    ontologies = old_ontologies - new_ontologies  
    ontologies.each do |ont|
      ontology = LinkedData::Client::Models::Ontology.find(ont)
      if object.type.match(/\/([^\/]+)$/)[1] == 'Group'
        ontology.group.delete(object.id)
      else 
        ontology.hasDomain.delete(object.id)
      end
      ontology.update
    end
  end

  private

  def update_ontology_summary_only
    @ontology.summaryOnly = @submission.isRemote.eql?('3')
    @ontology.update
  end

  def convert_values_to_types(new_submission_hash)
    unless new_submission_hash[:contact].nil?
      new_submission_hash[:contact] = new_submission_hash[:contact].values
      new_submission_hash[:contact].delete_if { |c| c[:name].empty? || c[:email].empty? }
    end

    # Convert metadata that needs to be integer to int
    submission_metadata.map do |hash|
      if hash["enforce"].include?("integer")
        if !new_submission_hash[hash["attribute"]].nil? && !new_submission_hash[hash["attribute"]].eql?("")
          new_submission_hash[hash["attribute"].to_s.to_sym] = Integer(new_submission_hash[hash["attribute"].to_s.to_sym])
        end
      end
      if hash["enforce"].include?("boolean") && !new_submission_hash[hash["attribute"]].nil?
        if new_submission_hash[hash["attribute"]].eql?("true")
          new_submission_hash[hash["attribute"].to_s.to_sym] = true
        elsif new_submission_hash[hash["attribute"]].eql?("false")
          new_submission_hash[hash["attribute"].to_s.to_sym] = false
        else
          new_submission_hash[hash["attribute"].to_s.to_sym] = nil
        end
      end
    end
  end


  def submission_params(params)
    attributes = [
      :ontology,
      :description,
      :hasOntologyLanguage,
      :prefLabelProperty,
      :synonymProperty,
      :definitionProperty,
      :authorProperty,
      :obsoleteProperty,
      :obsoleteParent,
      :version,
      :status,
      :released,
      :isRemote,
      :pullLocation,
      :filePath,
      { contact: [:name, :email] },
      :homepage,
      :documentation,
      :publication
    ]

    submission_metadata.each do |m|

      m_attr = m["attribute"].to_sym

      attributes << if m["enforce"].include?("list")
                      [{ m_attr => {} }, { m_attr => []}]
                    else
                      m_attr
                    end
    end
    p = params.permit(attributes.uniq)
    p.to_h.transform_values do |v|
      if v.is_a? Hash
        v.values.reject(&:empty?)
      elsif v.is_a? Array
        v.reject(&:empty?)
      else
        v
      end
    end
  end
end
