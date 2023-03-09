class NoteDecorator < BaseDecorator
  include ApplicationHelper, NotesHelper

  def author
    view_context.content_tag(:span, get_username(creator), class: "note_author")
  end

  def body_content
    view_context.content_tag(:div, view_context.simple_format(body), class: "note_body") unless body.blank?
  end

  def created_date
    view_context.time_ago_in_words(DateTime.parse(created)) + " ago"
  end

  def proposal_content
    if proposal
      view_context.content_tag(:div, (proposal_html(self)).html_safe, class: "proposal")
    end
  end

  def reply_link
    view_context.link_to("reply", "#reply", class: "reply_reply", data: { parent_id: "#{id}", parent_type: "reply" })
  end

  def status
    if archived
      view_context.content_tag(:span, "archived", class: "archived_note")
    end
  end

  def title
    view_context.content_tag(:span, "#{subject}", class: "note_title")
  end
end
