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

    new_submission_hash[:titles] = new_submission_hash[:titles].values unless new_submission_hash[:titles].nil?
    unless new_submission_hash[:creators].nil?
      new_submission_hash[:creators] = new_submission_hash[:creators].values

      new_submission_hash[:creators].each do |c|
        c[:creatorIdentifiers] = c[:creatorIdentifiers].values unless c[:creatorIdentifiers].nil?
        c[:affiliations] = c[:affiliations].values  unless c[:affiliations].nil?
      end
    end

    # Convert metadata that needs to be integer to int
    @metadata.map do |hash|
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
      { contact: %i[name email] },
      :homepage,
      :documentation,
      :publication,
      :identifier,
      :is_doi_requested,
    ]

    @metadata.each do |m|

      m_attr = m["attribute"].to_sym

      attributes << if m["enforce"].include?("list")
                      [{ m_attr => {} }, { m_attr => []}]
                    else
                      m_attr
                    end
    end
    p = params.permit(attributes.uniq)
    p = p.to_h.transform_values do |v|
      if v.is_a? Hash
        v.values.reject(&:empty?)
      elsif v.is_a? Array
        v.reject(&:empty?)
      else
        v
      end
    end

    @metadata.each do |m|
      m_attr = m['attribute'].to_sym
      if p[m_attr] && m['enforce'].include?('list')
        p[m_attr] = Array(p[m_attr]) unless p[m_attr].is_a?(Array)
        p[m_attr] = p[m_attr].map { |x| x.is_a?(Hash) ? x.values : x }.flatten.uniq if m['enforce'].include?('Agent')
      end
    end

    p
  end
end
