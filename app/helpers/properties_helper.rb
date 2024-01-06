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
  def property_tree_component(root, selected_concept, acronym, language, sub_tree: false, id: nil, auto_click: false)
    tree_component(root, selected_concept, target_frame: 'property_show', sub_tree: sub_tree, id: id, auto_click: auto_click) do |child|
      property_tree_data(acronym, child, language)
    end
  end
end