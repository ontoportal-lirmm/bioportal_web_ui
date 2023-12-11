# frozen_string_literal: false

class TreeViewComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(id, ontology, concept_schemes, language, root, concept, auto_click: false, **html_options)
    @id = id
    @conceptid = concept.id
    @concept_schemes = concept_schemes.is_a?(String) ? concept_schemes.split(',') : Array(concept_schemes)
    @language = language
    @ontology = ontology
    @root = root
    @concept = concept
    @auto_click = auto_click
    @html_options = html_options
  end

  private

  def sub_tree?
    @root.id.eql?(@concept.id)
  end

  def tree_container(&block)
    if sub_tree?
      content_tag(:ul, capture(&block), class: 'pl-2 tree-border-left')
    else
      content_tag(:div, class: 'tree_wrapper hide-if-loading') do
        content_tag(:ul, capture(&block), class: 'simpleTree root', data: { controller: 'simple-tree',
                                                      'simple-tree': { 'auto-click-value': "#{auto_click?}" },
                                                      action: 'clicked->history#updateURL' })
      end
    end
  end

  def auto_click?
    @auto_click.to_s
  end

  # TDOD check where used
  def child_id(child)
    child.id.to_s.split('/').last
  end

  # TODO make this a component, and update its usages
  def tree_link_to_concept(child:, ontology_acronym:, active_style:, node: nil, concept_schemes: nil)
    render TreeLinkComponent.new(child: child, ontology_acronym: ontology_acronym,
                                 active_style: active_style,
                                 node: node,
                                 concept_schemes: concept_schemes, language: @language
    )
  end

end
  