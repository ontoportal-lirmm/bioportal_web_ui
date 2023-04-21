module LabelXlHelper

  def get_label_xl(ontology, label_xl_uri)
    ontology.explore.xl_labels({ include: 'all' }, label_xl_uri)
  end

  def get_label_xl_label(label_xl)
    if label_xl['literalForm'].nil? || label_xl['literalForm'].empty?
      extract_label_from(label_xl['@id']).html_safe
    else
      label_xl['literalForm']
    end
  end
end
