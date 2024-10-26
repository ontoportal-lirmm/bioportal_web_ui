# frozen_string_literal: true
module PropertiesHelper

  def property_link(acronym, child, language)
    child.id.eql?('bp_fake_root') ? '#' : "/ontologies/#{acronym}/properties/show?id=#{CGI.escape(child.id)}&language=#{language}"
  end

  def property_children_link(acronym, child, language)
    "/ajax/properties/children?propertyid=#{CGI.escape(child.id)}&language=#{language}&ontology=#{acronym}"
  end

  def property_tree_data(acronym, child, language)
    href = property_link(acronym, child, language)
    children_link = property_children_link(acronym, child, language)
    data = {
      propertyid: child.id
    }
    [children_link, data, href]
  end

  def property_tree_component(root, selected_concept, acronym, language, sub_tree: false, id: nil, auto_click: false, submission: @submission)
    tree_component(root, selected_concept, target_frame: 'property_show', sub_tree: sub_tree, id: id, auto_click: false, submission: submission) do |child|
      property_tree_data(acronym, child, language)
    end
  end

  def no_properties?
    @properties.nil? || @properties.empty?
  end

  def no_properties_alert
    render Display::AlertComponent.new do
      t('properties.no_properties_alert', acronym: @ontology.acronym)
    end
  end

  def get_property(id, acronym = params[:acronym], lang = request_lang, include: nil)
    LinkedData::Client::HTTP.get("/ontologies/#{acronym}/properties/#{helpers.encode_param(id)}", { lang: lang , include: include})
  end
end
