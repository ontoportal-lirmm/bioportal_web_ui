# frozen_string_literal: true

class TreeViewComponent < ViewComponent::Base
  include Turbo::FramesHelper


  renders_many :children, TreeLinkComponent

  def initialize(id:, auto_click: false, sub_tree: false, **html_options)
    @id = id
    @auto_click = auto_click
    @html_options = html_options
    @sub_tree = sub_tree
  end

  private

  def sub_tree?
    @sub_tree
  end

  def tree_container(&block)
    if sub_tree?
      content_tag(:ul, capture(&block), class: 'pl-2 tree-border-left')
    else
      content_tag(:div, class: 'tree_wrapper hide-if-loading') do
        content_tag(:ul, capture(&block), class: 'simpleTree root', data: { controller: 'simple-tree',
                                                      'simple-tree-auto-click-value': "#{auto_click?}",
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

end
  