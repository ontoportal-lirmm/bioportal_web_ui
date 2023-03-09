function bindAddRequestTermClick() {
  jQuery("a.add_request_term").live("click", function () {
    var id = jQuery(this).attr("data-parent-id");
    addRequestTermBox(id);
  });
}

function bindCancelRequestTermClick() {
  jQuery(".request_term_form_div .cancel").live("click", function () {
    removeRequestTermBox();
  });
}

function bindNewTermInstructionsClick() {
  jQuery("#new_term_instructions").live("click", function () {
    jQuery(this).trumbowyg({
      btns: [
        ["viewHTML"],
        ["undo", "redo"], // Only supported in Blink browsers
        ["formatting"],
        ["strong", "em", "del"],
        ["superscript", "subscript"],
        ["link"],
        ["insertImage"],
        ["justifyLeft", "justifyCenter", "justifyRight", "justifyFull"],
        ["unorderedList", "orderedList"],
        ["horizontalRule"],
        ["removeformat"],
        ["fullscreen"],
      ],
    });
    jQuery("#new_term_instructions_submit").show();
    jQuery("#new_term_instructions_cancel").show();
  });
}

function bindNewTermInstructionsSubmit() {
  jQuery("#new_term_instructions_submit").live("click", function () {
    saveNewTermInstructions();
  });
}

function bindNewTermInstructionsCancel() {
  jQuery("#new_term_instructions_cancel").live("click", function () {
    var oldVal = jQuery("#new_term_instructions_old").val().trim();
    var curVal = jQuery("#new_term_instructions").html().trim();

    if (oldVal != curVal) {
      if (confirm("Are you sure you want to discard your changes?")) {
        jQuery("#new_term_instructions").trumbowyg("destroy");
        jQuery("#new_term_instructions").html(oldVal);
        hideButtons();
      }
    } else {
      jQuery("#new_term_instructions").trumbowyg("destroy");
      hideButtons();
    }
  });
}

function preventNewTermInstructionsFormSubmit() {
  jQuery("#new_term_instructions_form").submit(function (e) {
    e.preventDefault(e);
  });
}

function clearProgressMessage(parentContainerID) {
  var progMsgElem = jQuery("#" + parentContainerID + " #progress_message");
  progMsgElem.hide();
  progMsgElem.html("");
}

function showProgressMessage(parentContainerID) {
  clearProgressMessage(parentContainerID);
  var msg = "Saving...";
  var progMsgElem = jQuery("#" + parentContainerID + " #progress_message");
  progMsgElem.text(msg).html();
  progMsgElem.show();
}

function saveNewTermInstructions() {
  var params = jQuery("#new_term_instructions_form").serialize();
  var newInstructions = jQuery("#new_term_instructions").html().trim();
  params += "&new_term_instructions=" + newInstructions;
  var parentContainerID = "new_term_instructions_container";
  showProgressMessage(parentContainerID);

  jQuery.ajax({
    type: "POST",
    url: "/ontolobridge/save_new_term_instructions",
    dataType: "json",
    data: params,
    success: function (data) {
      var status = data[1];

      if ((status && status >= 400) || data[0]["error"].length) {
        showStatusMessages("", data[0]["error"]);
      } else {
        jQuery("#new_term_instructions").trumbowyg("destroy");
        jQuery("#new_term_instructions_old").val(newInstructions);
        showStatusMessages(data[0]["success"], "");
        setTimeout(function () {
          clearStatusMessages();
        }, 5000);
      }
    },
    error: function (request, textStatus, errorThrown) {
      showStatusMessages("", errorThrown);
    },
    complete: function (request, textStatus) {
      clearProgressMessage(parentContainerID);
      hideButtons();
    },
  });
}

function hideButtons() {
  jQuery("#new_term_instructions_submit").hide();
  jQuery("#new_term_instructions_cancel").hide();
}

function bindRequestTermSaveClick() {
  var success = "";
  var error = "";
  var user = jQuery(document).data().bp.user;
  var ontology_id = jQuery(document).data().bp.ont_viewer.ontology_id;
  var params = jQuery("#request_term_form").serialize();
  params += "&ontology=" + ontology_id + "&email=" + user["email"];

  if (user["firstName"] && user["lastName"]) {
    params += "&submitter=" + user["firstName"] + " " + user["lastName"];
  }

  var parentContainerID = "proposal_buttons";
  showProgressMessage(parentContainerID);

  jQuery.ajax({
    type: "POST",
    url: "/ontolobridge",
    data: params,
    dataType: "json",
    success: function (data) {
      var status = data[1];

      if (status && status >= 400) {
        showStatusMessages("", data[0]["error"]);
      } else {
        var msg =
          "<strong>A new term request has been submitted successfully:</strong><br/><br/>";
        removeRequestTermBox();

        for (var i in data[0]) {
          msg += i + ": " + data[0][i] + "<br/>";
        }
        showStatusMessages(msg, error);
      }
    },
    error: function (request, textStatus, errorThrown) {
      error =
        "The following error has occurred: " +
        errorThrown +
        ". Please try again.";
      showStatusMessages(success, error);
    },
    complete: function (request, textStatus) {
      clearProgressMessage(parentContainerID);
    },
  });
}

function removeRequestTermBox() {
  jQuery(".request_term_form_div").html("");
}

function addRequestTermBox(id) {
  clearStatusMessages();
  var formContainer = jQuery(".request_term_form_div");
  var requestTermForm = requestTermFields(id, formContainer);
  var formID = requestTermForm.attr("id");
  var isPopulated = window.localStorage.getItem(formID + "_populated");

  if (isPopulated) {
    for (var key in window.localStorage) {
      if (key.startsWith(formID)) {
        var elemID = key.replace(formID + "_", "");
        var elem = jQuery("#" + formID + " #" + elemID);

        if (elem.attr("type") === "checkbox") {
          elem.prop("checked", true);
        } else if (elem.length > 0) {
          var val = window.localStorage.getItem(key);
          elem.val(val);
        }
        window.localStorage.removeItem(key);
      }
    }
  }
  formContainer.show();
  jQuery("#label").focus();
}

function clearStatusMessages() {
  jQuery("#ob_success_message").hide();
  jQuery("#ob_error_message").hide();
  jQuery("#ob_success_message").html("");
  jQuery("#ob_error_message").html("");
}

function showStatusMessages(success, error) {
  if (success.length > 0) {
    let ob = jQuery("#ob_success_message");
    console.log("show ob message");
    console.log(ob);
    ob.html(success);
    ob.show();
  }

  if (error.length > 0) {
    jQuery("#ob_error_message").text(error).html();
    jQuery("#ob_error_message").show();
  }
}

function requestTermButtons() {
  var buttonSubmit = jQuery("<button>")
    .attr("class", "btn")
    .attr("type", "submit")
    .attr("onclick", "")
    .addClass("save")
    .css("margin-right", "5px")
    .html("Submit");
  var buttonCancel = jQuery("<button>")
    .attr("class", "btn")
    .attr("type", "button")
    .attr("onclick", "")
    .addClass("cancel")
    .html("Cancel");
  var progressMessage = jQuery("<span>")
    .attr("id", "progress_message")
    .css("display", "none")
    .css("margin-left", "20px");
  return buttonSubmit.add(buttonCancel).add(progressMessage);
}

function appendTextArea(id, placeholder, div, isRequired, invalidMessage) {
  if (jQuery.browser.msie && parseInt(jQuery.browser.version) < 10) {
    div.append(jQuery("<span>").css("font-weight", "bold").html(text));
    div.append("<br/>");
  }

  var txtArea = jQuery("<textarea>", {
    rows: 1,
    cols: 1,
    id: id,
    name: id,
    placeholder: placeholder,
    css: { width: "500px", height: "100px", margin: "5px 0 5px 0" },
  });

  jQuery(txtArea).on("invalid", function (e) {
    this.setCustomValidity(invalidMessage);
  });

  jQuery(txtArea).on("input", function (e) {
    this.setCustomValidity("");
  });

  if (isRequired) {
    txtArea.prop("required", true);
    txtArea.attr("class", "req");
  }
  div.append(txtArea);
  div.append("<br/>");
}

function appendField(id, text, div, isRequired, invalidMessage) {
  if (jQuery.browser.msie && parseInt(jQuery.browser.version) < 10) {
    div.append(jQuery("<span>").css("font-weight", "bold").html(text));
    div.append("<br/>");
  }

  var ipt = jQuery("<input>", {
    type: "text",
    id: id,
    name: id,
    placeholder: text,
    css: { width: "500px", margin: "5px 0 5px 0" },
  });

  jQuery(ipt).on("invalid", function (e) {
    this.setCustomValidity(invalidMessage);
  });

  jQuery(ipt).on("input", function (e) {
    this.setCustomValidity("");
  });

  if (isRequired) {
    ipt.prop("required", true);
    ipt.attr("class", "req");
  }
  div.append(ipt);
  div.append("<br/>");
}

function requestTermFields(id, container) {
  container.html("");
  var requestTermForm = jQuery("<form/>", {
    id: "request_term_form",
    name: "request_term_form",
  });

  appendField(
    "label",
    "Enter term label (required)",
    requestTermForm,
    true,
    "Please enter a label for a new term"
  );
  appendTextArea(
    "description",
    "Enter term description (required)",
    requestTermForm,
    true,
    "Please enter a description for a new term"
  );

  requestTermForm.append(
    jQuery("<span>")
      .css("font-weight", "bold")
      .css("margin", "5px 0 5px 0")
      .html("Superclass: ")
  );
  requestTermForm.append(g_prefLabel + "<br/>");

  appendField(
    "references",
    "Enter references - links that provide more info on the term",
    requestTermForm,
    false,
    "Please enter references for a new term. References are any links (either URIs or URLs) that provide more information about the term."
  );
  appendTextArea(
    "justification",
    "Enter justification for the term - the reason it should be added",
    requestTermForm,
    false,
    "Please enter a justification. Justifications are notes provided by the submitter to justify the term; often this will not be necessary, since for most routine cases the label/description/position will be sufficient, but sometimes it may be necessary to justify why a new term is necessary."
  );

  requestTermForm
    .append(
      jQuery("<input>")
        .attr("type", "checkbox")
        .attr("name", "notification_request")
        .attr("id", "notification_request")
        .css("height", "15px")
    )
    .append("&nbsp;&nbsp;");
  requestTermForm.append(
    jQuery("<input>")
      .attr("type", "hidden")
      .attr("name", "superclass")
      .attr("id", "superclass")
      .attr("value", id)
  );
  requestTermForm.append(
    jQuery("<label>")
      .attr("for", "notification_request")
      .attr("id", "notification_request")
      .css("margin", "0 0 10px 0")
      .append("Email submitter when there is a status change")
  );
  requestTermForm.append(
    jQuery("<div>").attr("id", "proposal_buttons").append(requestTermButtons())
  );
  container.append(requestTermForm);

  requestTermForm.submit(function (e) {
    e.preventDefault(e);
    bindRequestTermSaveClick();
    return false;
  });

  return requestTermForm;
}

function obTriggerNewTermRequestFormSave() {
  var ont = jQuery(document).data().bp.ontology;
  var ob_onts = jQuery(document).data().bp.ontolobridge_ontologies;

  // Execute only if ontology is Ontolobridge-enabled
  if (
    Object.entries(ont).length > 0 &&
    ob_onts &&
    ob_onts.length > 0 &&
    ob_onts.includes(ont["acronym"])
  ) {
    var formName = "request_term_form";

    jQuery("#" + formName + " input, #" + formName + " textarea").each(
      function () {
        var input = jQuery(this);
        var val = input.val().trim();

        if (
          input.attr("type") === "checkbox" &&
          input.prop("checked") === true
        ) {
          window.localStorage.setItem(
            formName + "_" + input.attr("name"),
            "checkbox_checked"
          );
          window.localStorage.setItem(formName + "_populated", true);
        } else if (
          input.attr("type") !== "hidden" &&
          input.attr("type") !== "checkbox" &&
          val
        ) {
          window.localStorage.setItem(formName + "_" + input.attr("name"), val);
          window.localStorage.setItem(formName + "_populated", true);
        }
      }
    );
  }
}

jQuery(document).ready(function () {
  clearStatusMessages();
  bindAddRequestTermClick();
  bindCancelRequestTermClick();
  preventNewTermInstructionsFormSubmit();
  bindNewTermInstructionsSubmit();
  bindNewTermInstructionsCancel();
  bindNewTermInstructionsClick();
});
