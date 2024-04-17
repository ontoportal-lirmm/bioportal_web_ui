jQuery(document).ready(function(){
  new SearchAnalytics().bindTracker();
});

function Analytics() {
  this.track = function(segment, analytics_action, params, callback) {
    params["segment"] = segment;
    params["analytics_action"] = analytics_action;
    jQuery.ajax({
      url: "/analytics",
      data: params,
      type: "POST",
      timeout: 100,
      success: function(){
        if (typeof callback === "function") callback();
      },
      error: function(){
        if (typeof callback === "function") callback();
      }
    });
  };
}

function SearchAnalytics() {
  this.bindTracker = function() {
    jQuery(document).on("click", "#search_results_container div.class_link a", function(e) {
      e.preventDefault();

      var link;
      if (e.target.nodeName == "SPAN") {
        link = jQuery(e.target.parentElement);
      } else {
        link = jQuery(e.target);
      }

      var href = link.attr("href");
      var params = new SearchAnalytics().linkInformation(link);
      new Analytics().track("search", "result_clicked", params, function(){
        window.location.href = href;
      });
    });
  };

  this.linkInformation = function(link) {
    var info = {}, resultsIndex = 0;
    var ontologyPosition = jQuery("#search_results div.search_result").index(jQuery(link).closest(".search_result")) + 1;

    info.ontology_clicked = link.closest(".search_result").data("bp_ont_id");

    // Find out the position of the search result in the list
    if (link.closest(".additional_results").length === 0) {
      info.position = ontologyPosition;
    } else {
      info.position = link.closest(".additional_results").children(".search_result_additional").index(link.closest(".search_result_additional")) + 1;
    }

    // Was this an additional result or a top-level
    info.additional_result = link.closest('div.search_result_additional').length > 0;

    // Get the name of ontologies higher in the list
    if (info.position > 1 || info.additional_result === true) {
      var results = jQuery("#search_results div.search_result");
      info.higher_ontologies = [];
      while (resultsIndex < ontologyPosition - 1) {
        info.higher_ontologies.push(jQuery(results[resultsIndex]).data("bp_ont_id"));
        resultsIndex += 1;
      }
    }

    // Concept id
    info.concept_id = link.data("bp_conceptid");

    // Search query
    info.query = jQuery("#search_keywords").val();

    // Exact match
    info.exact_match = link.data("exact_match");

    return info;
  };
}

