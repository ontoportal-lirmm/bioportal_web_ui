function setupReviewFacebox() {
  jQuery("a.create_review").attr("rel", "facebox[.facebox_review]");
  jQuery("a.create_review").facebox();
}

function setupReviewFaceboxSizing() {
  jQuery(document).bind('afterReveal.facebox', function() {
    jQuery("div.facebox_review").parents("div#facebox").width('850px');
    jQuery("div.facebox_review").width('820px');
    jQuery("div.facebox_review").parents("div#facebox").css("max-height", jQuery(window).height() - (jQuery("#facebox").offset().top - jQuery(window).scrollTop()) * 2 + "px");
    jQuery("div.facebox_review").parents("div#facebox").centerElement();
  });
}

function bindReviewCreationFormEvents(createReviewForm) {
  let spinner = createReviewForm.closest(".reviews_list_container").find(".review_toolbar_spinner");
  let reviewsList = createReviewForm.closest(".reviews_list_container").find(".reviews_list");

  createReviewForm.on("ajax:before", function(event, response, status, xhr) {
    spinner.show();
  });
  createReviewForm.on("ajax:success", function(event, response, status, xhr) {
    spinner.hide();
    createReviewForm.empty().hide();
    reviewsList.prepend(jQuery(response));
  });
  createReviewForm.on("ajax:error", function(event, xhr, status, error) {
    spinner.hide();
    let addendum = "";
    if (xhr.responseJSON) {
      addendum = ":\n" + JSON.stringify(xhr.responseJSON, null, 2);
    }
    alertify.alert("An error occurred when adding the review" + addendum);
  });
  createReviewForm.on("click", ".dismiss-dialog", function(event) {
    createReviewForm.empty().hide();
  });
}

function bindAddReviewClick() {
  jQuery("a.add_review").on("click", function(event) {
    let spinner = jQuery(event.target).siblings(".review_toolbar_spinner");
    let createReviewForm = jQuery(event.target).closest(".reviews_list_container").find(".create_review_form");

    spinner.show();

    jQuery.ajax(
        "/reviews/new",
        {
          "data": {
            "ontology": event.target.dataset.ontology
          }
        }
    ).done(function(data){
      createReviewForm
          .empty()
          .append(jQuery(data)).show();
    }).fail(function(data){
      alertify.alert("Unable to open the review creation form");
    }).always(function(){
      spinner.hide();
    });
  });
}

function bindReviewEvents() {
  bindDeleteReviewClick();
  bindEditReviewClick();
}

function getReviewLocalNameFromButton(triggeringButtonSelector) {
  return triggeringButtonSelector.data("review").split("/").pop();
}

function bindDeleteReviewClick() {
  jQuery(".reviews_list").on("click", "button.delete-review", function() {
    let triggeringButtonSelector = jQuery(this);

    let spinner = triggeringButtonSelector.siblings(".individual_review_spinner");
    spinner.css("visibility", "visible");
    jQuery.ajax(
        "/reviews/" + encodeURIComponent(getReviewLocalNameFromButton(triggeringButtonSelector)),
        {
          "method": "delete",
        }
    ).done(function(data) {
      triggeringButtonSelector.closest(".ontology_review").remove();
      // no need to hide the spinner, as it is deleted together with the review box
    }).fail(function(data) {
      spinner.css("visibility", "hidden");
      alertify.alert("Unable to delete the review");
    })
  });
}

function bindEditReviewClick() {
  jQuery(".reviews_list").on("click", "button.edit-review", function() {
    let triggeringButtonSelector = jQuery(this);

    let spinner = triggeringButtonSelector.siblings(".individual_review_spinner");
    jQuery(document).data().bp.reviewsTab.currentReviewElement = triggeringButtonSelector.closest(".ontology_review")[0];
    jQuery.facebox({'ajax': "/reviews/" + encodeURIComponent(encodeURIComponent(getReviewLocalNameFromButton(triggeringButtonSelector))) + "/edit"}, "facebox_review");
  })
}

function setupReviewsFacebox() {
  // facebox sizing
  jQuery(document).bind('afterReveal.facebox', function() {
    jQuery("div.facebox_review").parents("div#facebox").width('850px');
    jQuery("div.facebox_review").width('820px');
    jQuery("div.facebox_review").parents("div#facebox").css("max-height", jQuery(window).height() - (jQuery("#facebox").offset().top - jQuery(window).scrollTop()) * 2 + "px");
    jQuery("div.facebox_review").parents("div#facebox").centerElement();
  });

}

function bindReviewEditFormEvents() {
  jQuery(document).on("click", ".facebox_review .dismiss-dialog", function (event) {
    jQuery(document).trigger('close.facebox');
  });

  jQuery(document).on('ajax:success', ".facebox_review #edit_review_form", (event, response, status, xhr) => {
    jQuery(document).trigger('close.facebox');
    jQuery(jQuery(document).data().bp.reviewsTab.currentReviewElement).replaceWith(jQuery(response));
    jQuery(document).data().bp.reviewsTab.currentReviewElement = undefined;
  });
  jQuery(document).on('ajax:error', "#facebox form.admin-collection-form", (event, xhr, status, error) => {
    alertify.alert("Unable to update the review");
  });
}

jQuery(document).data().bp.reviewsTab = {};
jQuery(document).data().bp.reviewsTab.init = function() {
  setupReviewsFacebox();
  bindAddReviewClick();

  let createReviewForm = jQuery(".reviews_list_container").find(".create_review_form");
  bindReviewCreationFormEvents(createReviewForm);
  bindReviewEditFormEvents();
  bindReviewEvents();

};