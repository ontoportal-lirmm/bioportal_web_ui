// Widget-specific code

// Set a variable to check to see if this script is loaded
var BP_INTERNAL_FORM_COMPLETE_LOADED = true;

// Set the defaults if they haven't been set yet
if (typeof BP_INTERNAL_SEARCH_SERVER === 'undefined') {
  var BP_INTERNAL_SEARCH_SERVER = jQuery(document).data().bp.config.ui_url;
}
if (typeof BP_INTERNAL_SITE === 'undefined') {
  var BP_INTERNAL_SITE = "BioPortal";
}
if (typeof BP_INTERNAL_ORG === 'undefined') {
  var BP_INTERNAL_ORG = "NCBO";
}
if (typeof BP_INTERNAL_ONTOLOGIES === 'undefined') {
  var BP_INTERNAL_ONTOLOGIES = "";
}

var BP_INTERNAL_ORG_SITE = (BP_INTERNAL_ORG == "") ? BP_INTERNAL_SITE : BP_INTERNAL_ORG + " " + BP_INTERNAL_SITE;

function determineHTTPS(url) {
  return url.replace("http:", ('https:' == document.location.protocol ? 'https:' : 'http:'));
}

BP_INTERNAL_SEARCH_SERVER = determineHTTPS(BP_INTERNAL_SEARCH_SERVER);

jQuery(document).ready(function(){
  // Install any CSS we need (check to make sure it hasn't been loaded)
  if (jQuery('link[href$="' + BP_INTERNAL_SEARCH_SERVER + '/javascripts/JqueryPlugins/autocomplete/jquery.autocomplete.css"]')) {
    jQuery("head").append("<link>");
    css = jQuery("head").children(":last");
    css.attr({
      rel:  "stylesheet",
      type: "text/css",
      href: BP_INTERNAL_SEARCH_SERVER + "/javascripts/JqueryPlugins/autocomplete/jquery.autocomplete.css"
    });
  }
});



