class Display::SearchResultComponent < ViewComponent::Base
  include ModalHelper
  renders_many :subresults, Display::SearchResultComponent
  renders_many :reuses, Display::SearchResultComponent
  def initialize(number: 0,title: nil, ontology_acronym: nil ,uri: nil, definition: nil, link: nil,  is_sub_component: false)
      @title = title
      @uri = uri
      @definition = definition
      @link = link
      @is_sub_component = is_sub_component
      @ontology_acronym = ontology_acronym
      @number = number.to_s
  end

  def sub_component_class
      @is_sub_component ? 'sub-component' : ''
  end

  def sub_ontologies_id 
    string = @number+'_sub_ontologies'
  end

  def reuses_id 
    string = @number+'_reuses'
  end

  def details_button
      link_to_modal(nil, "/ajax/class_details?modal=true&ontology=#{@ontology_acronym}&conceptid=#{@uri}&styled=false", data: { show_modal_title_value: @title, show_modal_size_value: 'modal-xl' }) do
        content_tag(:div, class: 'button') do
          concat inline_svg_tag('icons/details.svg')
          concat content_tag(:div, class: 'text') { t('search.result_component.details') }
        end
      end
  end

  def visualize_button
      link_to_modal(nil, "/ajax/biomixer/?ontology=#{@ontology_acronym}&conceptid=#{@uri}", data: { show_modal_title_value: @title, show_modal_size_value: 'modal-xl' }) do
        content_tag(:div, class: 'button') do
          concat inline_svg_tag('icons/visualize.svg')
          concat content_tag(:div, class: 'text') { t('search.result_component.visualize') }
        end
      end
  end

  def reveal_ontologies_button(text,id)
    content_tag(:div, class: 'button icon-right', 'data-action': "click->reveal-component#toggle", 'data-id': id) do
      concat(content_tag(:div, class: 'text') do
        text
      end)
      concat(inline_svg_tag("icons/arrow-down.svg"))
    end
  end
end