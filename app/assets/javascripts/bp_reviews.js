function setupReviewFacebox() {
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

