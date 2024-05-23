# frozen_string_literal: true

class TreeLinkComponent < ViewComponent::Base
  include MultiLanguagesHelper, ModalHelper, ApplicationHelper
  def initialize(child:, href:, children_href: , selected: false , data: {}, muted: false, target_frame: nil, open_in_modal: false)
    @child = child
    @active_style = selected ? 'active' : ''
    #@icons = child.relation_icon(node)
    @muted_style = muted ? 'text-muted' : ''
    @href = href
    @children_link = children_href
    label = (@child.prefLabel || @child.label) rescue @child.id
    if label.nil?
      @pref_label_html = link_last_part(child.id)
    else
      pref_label_lang, @pref_label_html = select_language_label(label)
      pref_label_lang = pref_label_lang.to_s.upcase
      @tooltip = pref_label_lang.eql?("@NONE") ? "" : pref_label_lang

      if child.obsolete?
        @pref_label_html = "<span class='obsolete_class'>#{@pref_label_html}</span>".html_safe
      end
    end
    @data ||= { controller: 'tooltip', 'tooltip-position-value': 'right', turbo: true, 'turbo-frame': target_frame, action: 'click->simple-tree#select'}

    @data.merge!(data) do |_, old, new|
      "#{old} #{new}"
    end

    @open_in_modal = open_in_modal
  end


  # This gives a very hacky short code to use to uniquely represent a class
  # based on its parent in a tree. Used for unique ids in HTML for the tree view
  def short_uuid
    rand(36 ** 8).to_s(36)
  end

  # TDOD check where used
  def child_id
    @child.id.to_s.split('/').last
  end

  def open?
    @child.expanded? ? 'open' : ''
  end

  def border_left
    !@child.hasChildren  ?  'pl-3 tree-border-left' :  ''
  end

  def li_id
    @child.id.eql?('bp_fake_root') ? 'bp_fake_root' : short_uuid
  end

  def self.tree_close_icon
    "<i class='fas fa-chevron-down text-primary' data-action='click->simple-tree#toggleChildren'></i>".html_safe
  end

  def open_children_link
    return unless @child.hasChildren
    if @child.expanded?
      self.class.tree_close_icon
    else
      content_tag('turbo_frame', id: "#{child_id}_open_link") do
        link_to @children_link,
                data: { turbo: true, turbo_frame: "#{child_id + '_childs'}" } do
          content_tag(:i, nil, class: "fas fa-chevron-right")
        end
      end
    end

  end

end
