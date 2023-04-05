var ontNotesTable;
var ont_columns = { archived: 3, date: 7, subjectSort: 2 };

jQuery(document).ready(function(){
  setupNotesFaceboxSizing();
  bindAddCommentClick();
  bindAddProposalClick();
  bindDeleteNoteClick();
  bindProposalChange();
  bindReplyClick();
  bindReplyCancelClick();
  bindReplySaveClick();
  // Wire up subscriptions button activity
  jQuery("a.subscribe_to_notes").live("click", function(){
    subscribeToNotes(this);
  });
  jQuery("#hide_archived_ont").click(function(){
    hideOrUnhideArchivedOntNotes();
  });
});

NOTES_PROPOSAL_TYPES = {
  "ProposalNewClass": "New Class Proposal",
  "ProposalChangeHierarchy": "New Relationship Proposal",
  "ProposalChangeProperty": "Change Property Value Proposal"
}

function getUser() {
  return jQuery(document).data().bp.user;
}

function setupNotesFacebox() {
  jQuery("a.notes_list_link").attr("rel", "facebox[.facebox_note]");
  jQuery("a.notes_list_link").each(function() {
    if (!jQuery(this).data().faceboxInit) {
      jQuery(this).facebox();
      jQuery(this).data().faceboxInit = true;
    }
  });;
}

function setupNotesFaceboxSizing() {
  jQuery(document).bind('afterReveal.facebox', function() {
    jQuery("div.facebox_note").parents("div#facebox").width('850px');
    jQuery("div.facebox_note").width('820px');
    jQuery("div.facebox_note").parents("div#facebox").css("max-height", jQuery(window).height() - (jQuery("#facebox").offset().top - jQuery(window).scrollTop()) * 2 + "px");
    jQuery("div.facebox_note").parents("div#facebox").centerElement();
  });
}

function bindAddCommentClick() {
  jQuery("a.add_comment").live('click', function(){
    var id = jQuery(this).attr("data-parent-id");
    var type = jQuery(this).attr("data-parent-type");
    var prefLabel = jQuery(this).attr("data-parent-preflabel") || null; // only for class notes
    addCommentBox(id, type, prefLabel, this);
  });
}

function bindAddProposalClick() {
  jQuery("a.add_proposal").live('click', function(){
    var id = jQuery(this).attr("data-parent-id");
    var type = jQuery(this).attr("data-parent-type");
    var prefLabel = jQuery(this).attr("data-parent-preflabel") || null; // only for class proposals
    addProposalBox(id, type, prefLabel, this);
  });
}

function bindDeleteNoteClick() {
  jQuery("a.delete_note").live('click', function() {
    let id = jQuery(this).attr("data-parent-id");
    let type = jQuery(this).attr("data-parent-type");
    let notesContentSelector = jQuery(this).closest("#notes_content");
    let noteListClass = type == "ontology" ? "notes_ont_list_table" : "notes_concept_list_table";
    let selectedCheckBoxes = notesContentSelector.find("." + noteListClass + " input.delete_note_checkbox:checked").get();

    let note2classes = {};
    for (let cb of selectedCheckBoxes) {
      if (typeof cb.dataset.relatedClass != undefined && cb.dataset.relatedClass) {
        note2classes[cb.dataset.note_id] = JSON.parse(cb.dataset.relatedClass);
      }
    }

    let selectedNotes = Object.getOwnPropertyNames(note2classes);

    if (selectedNotes.length == 0) return;

    jQuery(".delete_notes_error").html("");
    jQuery(".delete_notes_spinner").show();

    jQuery.ajax({
      type: "GET",
      url: "/ajax/notes/delete?noteids=" + selectedNotes.join(","),
      data: {
        "noteids": selectedNotes.join(",")
      }
    }).done(function (data) {
      let successfullyDeletedNotes = new Set(data.success || []);
      let erroneousNotes = new Set(data.error || []);

      let dataTable = notesContentSelector.find("." + noteListClass).DataTable();

      for (let selectedCheckBox of selectedCheckBoxes) {
        let noteId = selectedCheckBox.dataset.note_id;
        if (successfullyDeletedNotes.has(noteId)) {
          dataTable.row(selectedCheckBox.closest("tr")).remove();
        }
      }
      dataTable.draw();

      if (type == "ontology") { // we are on the ontology note tab
        //... delete the notes in the class notes tab too and invalidate the cache
        let ontologyContentSelector = jQuery("#ont_classes_content");
        for (let noteId of successfullyDeletedNotes) {
          let classes4note = note2classes[noteId];
          classes4note.forEach(cls => setCache(cls, null)); // invalidate cache
        }

        let currentClass = ontologyContentSelector.find("a.add_comment").map((i,v)=>v.dataset.parentId).get()[0] || null;
        if (currentClass != null) {
          let classNotesTable = ontologyContentSelector.find("table.concept_notes_list");
          let classNotesDataTable = classNotesTable.DataTable();

          for (let noteId of successfullyDeletedNotes) {
            let classes4note = note2classes[noteId];
            if (classes4note.indexOf(currentClass) != -1) {
              classNotesDataTable.row(classNotesTable.find("input[type='checkbox'][data-note_id='" + noteId + "']").closest("tr")).remove();
              jQuery("#note_count").html(parseInt(jQuery("#note_count").html()) - 1);
            }
          }

          classNotesDataTable.draw();
        } else { // the classes tab has not been loaded before, and thus the corresponding div is just empty. Retrieve the page again
          jQuery.bioportal.ont_pages["classes"].retrieve();
        }
      } else { // we are on the class note tab
        // decrement the note count
        jQuery("#note_count").html(parseInt(jQuery("#note_count").html()) - successfullyDeletedNotes.size);
        //... delete the notes in the ontology notes tab too
        if (typeof ontNotesTable !== "undefined") {
          let ontNotesDataTable = ontNotesTable.DataTable();
          for (let noteId of successfullyDeletedNotes) {
            ontNotesDataTable.row(ontNotesTable.find("input[type='checkbox'][data-note_id='" + noteId + "']").closest("tr")).remove();
          }
          ontNotesDataTable.draw();
        }
      }
    }).fail(function (jqXHR, textStatus, errorThrown) {
      jQuery(".delete_notes_error").text("Server error: " + textStatus);
    }).always(function() {
     jQuery(".delete_notes_spinner").hide();
    });
  });
}


function bindReplyClick() {
  jQuery("a.reply_reply").live('click', function(){
    addReplyBox(this);
    jQuery(this).hide();
  });
}

function bindReplyCancelClick() {
  jQuery(".reply .cancel, .create_note_form .cancel").live('click', function(){
    removeReplyBox(this);
  });
}

function bindProposalChange() {
  jQuery(".create_note_form .proposal_type").live('change', function(){
    var selector = jQuery(this);
    proposalFields(selector.val(), selector.parent().children(".proposal_container"));
  });
}

function bindReplySaveClick() {
  jQuery(".reply .save, .create_note_form .save").live('click', function(){
    var user = getUser();
    var id = jQuery(this).data("parent_id");
    var type = jQuery(this).data("parent_type");
    var button = this;
    var body = jQuery(this).closest(".reply_box").children(".reply_body").val();
    var subject = subjectForNote(button);
    var ontology_id = jQuery(document).data().bp.ont_viewer.ontology_id;
    jQuery(button).parent().children(".reply_status").html("");
    if (type === "class") {
      id = {class: id, ontology: ontology_id};
    }
    jQuery.ajax({
      type: "POST",
      url: "/notes",
      data: {parent: id, type: type, subject: subject, body: body, proposal: proposalMap(button), creator: user["id"]},
      success: function(data){
        var note = data;
        var status = data[1];
        if (status && status >= 400) {
          displayError(button);
        } else {
          addNoteOrReply(button, note);
          removeReplyBox(button);
        }
      },
      error: function(){displayError(button);}
    });
  });
}

function validateReply(button) {

}

function validateNote(button) {

}

function validateProposal(button) {

}

var displayError = function(button) {
  jQuery(button).parent().children(".reply_status").html("Error, please try again");
}

function addCommentBox(id, type, prefLabel, button) {
  var formContainer = jQuery(button).parents(".notes_list_container").children(".create_note_form");
  var commentSubject = jQuery("<input>")
    .attr("type", "text")
    .attr("placeholder", "Subject")
    .addClass("comment_subject")
    .add("<br>");
  var commentFields = commentSubject.add(commentForm(id,type, prefLabel));
  var commentWrapper = jQuery("<div>").addClass("reply_box").append(commentFields);
  formContainer.html(commentWrapper);
  formContainer.show();
}

function addProposalBox(id, type, prefLabel, button) {
  var formContainer = jQuery(button).parents(".notes_list_container").children(".create_note_form");
  var proposalForm = jQuery("<div>").addClass("reply_box");
  var select = jQuery("<select>").addClass("proposal_type");
  var proposalContainer;
  for (var proposalType in NOTES_PROPOSAL_TYPES) {
    select.append(jQuery("<option>").attr("value", proposalType).html(NOTES_PROPOSAL_TYPES[[proposalType]]));
  }
  proposalForm.html("Proposal type: ");
  proposalForm.append(select);
  proposalForm.append("<br/>");

  proposalContainer = jQuery("<div>").addClass("proposal_container");

  // Proposal-specific fields
  proposalFields(Object.keys(NOTES_PROPOSAL_TYPES).shift(), proposalContainer);

  proposalForm.append(proposalContainer);
  proposalForm.append(jQuery("<div>").addClass("proposal_buttons").append(commentButtons(id, type, prefLabel)));
  formContainer.html(proposalForm);
  formContainer.show();
}

function addNoteOrReply(button, note) {
  if (note["type"] === "http://data.bioontology.org/metadata/Note") {
    // Create a new note in the note table
    addNote(button, note);
  } else if (note["type"] === "http://data.bioontology.org/metadata/Reply") {
    // Create a new reply in the thread
    addReply(button, note);
  }
}

function getSubjectFromNoteObject(note) {
  return note["subject"] || "no subject";
}

function addNote(button, note) {
  var id = note["id"].split("/").pop();
  var deleteBoxHTML = generateNoteDeleteBox("delete_" + id, note).outerHtml();
  var noteLinkHTML = generateNoteLink(id, note).outerHtml()
  var user = getUser();
  var created = note["created"].split("T")[0];
  var noteType = getNoteType(note);
  var classLinkHTML = jQuery(button).data("parent_type") == "class" ? generateClassLink(jQuery(button).data("parent_id"), jQuery(button).data("parent_preflabel")).outerHtml() : "";
  var noteRow = [deleteBoxHTML, noteLinkHTML, getSubjectFromNoteObject(note), false, user["username"], noteType, classLinkHTML, created];
  // Add note to concept table (if we're on a concept page)
  if (jQuery(button).closest("#notes_content").find("table.concept_notes_list").length > 0) {
    jQuery("table.concept_notes_list").DataTable().row.add(
        [generateNoteDeleteBox( "delete_" + id, note).outerHtml(),
        generateNoteLink("concept_"+id, note).outerHtml(),
          user["username"],
          noteType,
          created
        ]).draw();
    jQuery("#note_count").html(parseInt(jQuery("#note_count").html()) + 1);
    jQuery("a#concept_"+id).facebox();
  }
  // Add note to main table
  if (typeof ontNotesTable !== "undefined") {
    ontNotesTable.DataTable().row.add(noteRow).draw();
  } else {
    jQuery.bioportal.ont_pages["notes"].retrieve(); // the ontology notes tab has not been displayed yet, so just re-retrieve its data
  }
  jQuery("a#"+id).facebox();
}

function addReply(button, note) {
  var user = getUser();
  var reply = jQuery("<div>").addClass("reply");
  var replyAuthor = jQuery("<div>").addClass("reply_author").html("<b>"+user["username"]+"</b> seconds ago");
  var replyBody = jQuery("<div>").addClass("reply_body").html(note.body);
  var replyMeta = jQuery("<div>").addClass("reply_meta");
  replyMeta.append(jQuery("<a>").addClass("reply_reply").attr("data-parent-id", note["id"]).attr("data-parent-type", "reply").attr("href", "#reply").html("reply"));
  var discussion = jQuery("<div>").addClass("discussion").append(jQuery("<div>").addClass("discussion_container"));

  reply.append(replyAuthor).append(replyBody).append(replyMeta).append(discussion);
  jQuery(button).closest("div.reply").children(".discussion").children(".discussion_container").prepend(reply);
}

function addReplyBox(button) {
  var id = jQuery(button).attr("data-parent-id");
  var type = jQuery(button).attr("data-parent-type");
  var formHTML = commentForm(id, type);
  jQuery(button).closest("div.reply").children("div.reply_meta").append(jQuery("<div>").addClass("reply_box").html(formHTML));
}

function removeReplyBox(button) {
  jQuery(button).closest("div.reply").children(".reply_meta").children("a.reply_reply").show();
  jQuery(button).closest("div.reply").children(".reply_meta").children(".reply_box").remove();
  jQuery(button).closest(".create_note_form").html("");
}

function commentForm(id, type, prefLabel) {
  return commentTextArea().add(commentButtons(id, type, prefLabel));
}

function commentTextArea() {
  return jQuery("<textarea>")
    .addClass("reply_body")
    .attr("rows","1")
    .attr("cols","1")
    .attr("name","text")
    .attr("tabindex","0")
    .attr("placeholder","Comment")
    .css({"width": "500px", "height": "100px"})
    .add("<br>");
}

function commentButtons(id, type, prefLabel) {
  var button_submit = jQuery("<button>")
    .attr("type","submit")
    .attr("onclick","")
    .attr("data-parent_id", id)
    .attr("data-parent_type", type)
    .attr("data-parent_preflabel", prefLabel)
    .addClass("save")
    .html("save");
  var button_cancel = jQuery("<button>")
    .attr("type","button")
    .attr("onclick","")
    .addClass("cancel")
    .html("cancel");
  var span_status = jQuery("<span>")
    .addClass("reply_status")
    .css({"color": "red", "paddingLeft": "5px"});
  return button_submit.add(button_cancel).add(span_status);
}

function appendField(id, text, div) {
  if (jQuery.browser.msie && parseInt(jQuery.browser.version) < 10) {
    div.append(jQuery("<span>").css("font-weight", "bold").html(text));
    div.append("<br/>");
  }
  div.append(jQuery("<input>").attr("type", "text").attr("id", id).attr("placeholder", text));
  div.append("<br/>");
}

function proposalFields(type, container) {
  container.html("");
  appendField("reasonForChange", "Reason for change", container);
  if (type === "ProposalChangeHierarchy") {
    appendField("newTarget", "New target", container);
    appendField("oldTarget", "Old target", container);
    appendField("newRelationshipType", "Relationship type", container);
  } else if (type === "ProposalChangeProperty") {
    appendField("propertyId", "Property id", container);
    appendField("newValue", "New value", container);
    appendField("oldValue", "Old Value", container);
  } else if (type === "ProposalNewClass") {
    appendField("classId", "Class id", container);
    appendField("label", "Label", container);
    appendField("synonym", "Synonym", container);
    appendField("definition", "Definition", container);
    appendField("parent", "Parent", container);
  }
}

function proposalMap(button) {
  var formContainer = jQuery(button).parents(".notes_list_container").children(".create_note_form");
  var lists = ["synonym", "definition", "newRelationshipType"];
  var map = {};
  map["type"] = formContainer.find(".proposal_type").val();
  console.log(formContainer.find(".proposal_container input"))
  formContainer.find(".proposal_container input").each(function(){
    var input = jQuery(this);
    var id = input.attr("id");
    var val = (jQuery.inArray(id, lists) >= 0) ? input.val().split(",") : input.val();
    map[id] = val;
  });
  return map;
}

function subjectForNote(button) {
  var subject = jQuery(button).closest(".reply_box").children(".comment_subject").val();
  var reasonForChange = jQuery("input#reasonForChange");
  if (typeof subject === "undefined" || (subject.length === 0 && reasonForChange.length > 0)) {
    subject = NOTES_PROPOSAL_TYPES[$(".proposal_type").val()] + ": " + reasonForChange.val();
  }
  return subject;
}

function generateNoteLink(id, note) {
  return jQuery("<a>")
    .addClass("ont_notes_list_link")
    .addClass("notes_list_link")
    .attr("href", "/ontologies/"+jQuery(document).data().bp.ont_viewer.ontology_id+"/notes/"+encodeURIComponent(note["id"]))
    .attr("id", id)
    .text(getSubjectFromNoteObject(note));
}

function generateClassLink(id, prefLabel) {
  return jQuery("<a>")
      .attr("href", "/ontologies/"+jQuery(document).data().bp.ont_viewer.ontology_id+"?p=classes&conceptid="+escape(id))
      .text(prefLabel);
}

function generateNoteDeleteBox(id, note) {
  return jQuery("<input>").attr("type", "checkbox").attr("id", id).addClass("delete_note_checkbox")
      .attr("data-note_id", note.id).attr("data-related-class", JSON.stringify(note.relatedClass));
}

function getNoteType(note) {
  if (typeof note["proposal"] !== "undefined") {
    return NOTES_PROPOSAL_TYPES[note["proposal"]["table"]["type"]];
  } else {
    return "Comment";
  }
}

function subscribeToNotes(button) {
  var ontologyId = jQuery(button).attr("data-bp_ontology_id");
  var isSubbed = jQuery(button).attr("data-bp_is_subbed");
  var userId = jQuery(button).attr("data-bp_user_id");

  jQuery(".notes_sub_error").html("");
  jQuery(".notes_subscribe_spinner").show();

  jQuery.ajax({
    type: "POST",
    url: "/subscriptions?user_id="+userId+"&ontology_id="+ontologyId+"&subbed="+isSubbed,
    dataType: "json",
    success: function(data) {
      jQuery(".notes_subscribe_spinner").hide();

      // Change subbed value on a element
      var subbedVal = (isSubbed == "true") ? "false" : "true";
      jQuery("a.subscribe_to_notes").attr("data-bp_is_subbed", subbedVal);

      // Change button text
      var txt = jQuery("a.subscribe_to_notes span.ui-button-text").html();
      var newButtonText = txt.match("Unsubscribe") ? txt.replace("Unsubscribe", "Subscribe") : txt.replace("Subscribe", "Unsubscribe");
      jQuery("a.subscribe_to_notes span.ui-button-text").html(newButtonText);
    },
    error: function(data) {
      jQuery(".notes_subscribe_spinner").hide();
      jQuery(".notes_sub_error").html("Problem subscribing to emails, please try again");
    }
  });
}

function hideOrUnhideArchivedOntNotes() {
  if (jQuery("#hide_archived_ont:checked").val() !== undefined) {
    // Checked
    ontNotesTable.fnFilter('false', ont_columns.archived);
  } else {
    // Unchecked
    ontNotesTable.fnFilter('', ont_columns.archived, true, false);
  }
}