require 'cgi'

module NotesHelper

  NOTES_TAGS = %w(a br b em strong i)

  def recurse_replies(replies)
    return "" if replies.nil?
    html = ""
    replies.each do |reply|
      reply_html = <<-html
        <div class="reply">
          <div class="reply_author">
            <b>#{get_username(reply.creator)}</b> #{time_ago_in_words(DateTime.parse(@note.created))} ago
          </div>
          <div class="reply_body">
            #{sanitize reply.body, tags: NOTES_TAGS}<br/>
          </div>
          <div class="reply_meta">
            <a href="#reply" class="reply_reply" data-parent-id="#{reply.id}" data-parent-type="reply">reply</a>
          </div>
          <div class="discussion">
            <div class="discussion_container">
              #{recurse_replies(reply.respond_to?(:children) ? reply.children : nil)}
            </div>
          </div>
        </div>
      html
      html << reply_html
    end
    html
  end

  def proposal_html(note)
    return "" unless note.respond_to?(:proposal) && note.proposal
    case note.proposal.type
    when "ProposalNewClass"
      html = <<-html
        <table class="proposal">
          <tr>
            <th>Reason for Change</th>
            <td>#{note.proposal.reasonForChange}</td>
          <tr>
            <th>Contact Info</th>
            <td>#{note.proposal.contactInfo}</td>
          </tr>
          <tr>
            <th>Preferred Name</th>
            <td>#{note.proposal.label}</td>
          <tr>
            <th>Provisional id</th>
            <td>#{note.proposal.classId}</td>
          <tr>
            <th>Parent</th>
            <td>#{note.proposal.parent}</td>
          </tr>
          <tr>
            <th>Synonyms</th>
            <td>#{note.proposal.synonym.join(", ")}</td>
          </tr>
          <tr>
            <th>Definition</th>
            <td>#{note.proposal.definition.join(", ")}</td>
          </tr>
        </table>
      html
    when "ProposalChangeHierarchy"
      html = <<-html
        <table class="proposal">
          <tr>
            <th>Relationship Type</th>
            <td>#{note.proposal.newRelationshipType.join(", ")}</td>
          </tr>
          <tr>
            <th>New Relationship Target</th>
            <td colspan="3">#{note.proposal.newTarget}</td>
          </tr>
          <tr>
            <th>Old Relationship Target</th>
            <td colspan="3">#{note.proposal.oldTarget}</td>
          </tr>
          <tr>
            <th>Reason for Change</th>
            <td>#{note.proposal.reasonForChange}</td>
          <tr>
            <th>Contact Info</th>
            <td>#{note.proposal.contactInfo}</td>
          </tr>
        </table>
      html
    when "ProposalChangeProperty"
      html = <<-html
        <table class="proposal">
          <tr>
            <th>Property id</th>
            <td>#{note.proposal.propertyId}</td>
          </tr>
          <tr>
            <th>New Property Value</th>
            <td colspan="3">#{note.proposal.newValue}</td>
          </tr>
          <tr>
            <th>Old Property Value</th>
            <td colspan="3">#{note.proposal.oldValue}</td>
          </tr>
          <tr>
            <th>Reason for Change</th>
            <td>#{note.proposal.reasonForChange}</td>
          <tr>
            <th>Contact Info</th>
            <td>#{note.proposal.contactInfo}</td>
          </tr>
        </table>
      html
    end

    html
  end

  def get_note_type_text(note_type)
    case note_type
    when "Comment"
      return "Comment"
    when "ProposalNewClass"
      return "New Class Proposal"
    when "ProposalChangeHierarchy"
      return "New Relationship Proposal"
    when "ProposalChangeProperty"
      return "Change Property Value Proposal"
    end
  end
  

  def delete_button
    user = session[:user]
    # TODO_REV: Enable anonymous user
    # user ||= anonymous_user

    params = "data-bp_user_id='#{user.id}'"
    spinner = '<span class="delete_notes_spinner" style="display: none;">' + image_tag("spinners/spinner_000000_16px.gif", style: "vertical-align: text-bottom;") + '</span>'
    error = "<span style='color: red;' class='delete_notes_error'></span>"
    return "<a href='#' onclick='deleteNotes(this);return false;' style='display: inline-block !important;' class='notes_delete link_button' #{params}>Delete selected notes</a> #{spinner} #{error}"
  end

end
