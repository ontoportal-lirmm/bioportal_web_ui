// jQuery check, if it's not present then include it
// jQuery check, if it's not present then include it
function bpMinVersion(min, actual) {
  function parseVersionString (str) {
    if (typeof(str) != 'string') { return false; }
    var x = str.split('.');
    var maj = parseInt(x[0]) || 0;
    var min = parseInt(x[1]) || 0;
    var pat = parseInt(x[2]) || 0;
    return {
      major: maj,
      minor: min,
      patch: pat
    }
  }

  var minParsed = parseVersionString(min);
  var actualParsed = parseVersionString(actual);
  if (actualParsed.major > minParsed.major) {
    return true;
  } else if (actualParsed.major == minParsed.major &&
             actualParsed.minor > minParsed.minor) {
    return true;
  } else if (actualParsed.major == minParsed.major &&
             actualParsed.minor == minParsed.minor &&
             actualParsed.patch > minParsed.patch) {
    return true;
  }
  return false;
}

if (typeof jQuery == 'undefined') {
  var jq, jqMigrate, scriptLoc = document.getElementsByTagName('script')[0].parentElement;
  jq = document.createElement('script');
  jqMigrate = document.createElement('script');
  jq.type = jqMigrate.type = "text/javascript";
  jq.src = "//code.jquery.com/jquery-1.11.2.min.js";
  jqMigrate.src = "//code.jquery.com/jquery-migrate-1.2.1.min.js";
  jq.onload = function() {
    jqMigrate.onload = bpQuickJumpOnLoad;
    scriptLoc.appendChild(jqMigrate);
  }
  scriptLoc.appendChild(jq);
} else if (bpMinVersion("1.9", $.fn.jquery)) {
  var jqMigrate = document.createElement('script');
  jqMigrate.type = "text/javascript";
  jqMigrate.src = "//code.jquery.com/jquery-migrate-1.2.1.min.js";
  jqMigrate.onload = bpQuickJumpOnLoad;
  document.getElementsByTagName('head')[0].appendChild(jqMigrate);
} else {
  bpQuickJumpOnLoad();
}

// ***********************************
// Widget-specific code
// ***********************************

// Set the defaults if they haven't been set yet
if (typeof BP_SEARCH_SERVER === 'undefined') {
    var BP_SEARCH_SERVER = "http://bioportal.bioontology.org";
}

if (typeof BP_SITE === 'undefined') {
    var BP_SITE = "BioPortal";
}

if (typeof BP_ORG === 'undefined') {
    var BP_ORG = "NCBO";
}

var BP_ORG_SITE = (BP_ORG == "") ? BP_SITE : BP_ORG + " " + BP_SITE;

if (BP_ontology_id == undefined || BP_ontology_id == "all") {
    var BP_ontology_id = ""
}

if (BP_search_branch == undefined) {
    var BP_search_branch = ""
}

if (typeof BP_include_definitions === 'undefined' || BP_include_definitions !== true) {
    var BP_include_definitions = false;
}

function determineHTTPS(url) {
    return url.replace("http:", ('https:' == document.location.protocol ? 'https:' : 'http:'));
}

BP_SEARCH_SERVER = determineHTTPS(BP_SEARCH_SERVER);

var jumpTo_searchBoxID = "BP_search_box",
    jumpTo_searchBoxSelector = "#" + jumpTo_searchBoxID,
    jumpTo_searchBox = null;

// Process after document is fully loaded
function bpQuickJumpOnLoad() {
  jQuery(document).ready(function() {
      // Install any CSS we need (check to make sure it hasn't been loaded)
      if (jQuery('link[href$="' + BP_SEARCH_SERVER + '/javascripts/JqueryPlugins/autocomplete/jquery.autocomplete.css"]')) {
          jQuery("head").append("<link>");
          css = jQuery("head").children(":last");
          css.attr({
              rel: "stylesheet",
              type: "text/css",
              href: BP_SEARCH_SERVER + "/javascripts/JqueryPlugins/autocomplete/jquery.autocomplete.css"
          });
      }

      jQuery("#bp_quick_jump").append("Jump To: <input type=\"textbox\" id=\"" + jumpTo_searchBoxID + "\" size=\"30\"> <input type=\"button\" value=\"Go to " + BP_SITE + "\" onclick=\"jumpTo_jump_clicked();\">");
      jQuery("#bp_quick_jump").append("<input type='hidden' id='jump_to_concept_id'>");
      jQuery("#bp_quick_jump").append("<input type='hidden' id='jump_to_ontology_id'>");

      // Grab the specific scripts we need and fires it start event
      getScript(BP_SEARCH_SERVER + "/javascripts/JqueryPlugins/autocomplete/crossdomain_autocomplete.js").then( function() {
          jumpTo_setup_functions();
      });

  });
}

function getScript(url){
    return new Promise((resolve, reject) => {
        const script = document.createElement('script')
        script.src = url
        script.async = true

        script.onerror = reject

        script.onload = script.onreadystatechange = function() {
            const loadState = this.readyState

            if (loadState && loadState !== 'loaded' && loadState !== 'complete') return

            script.onload = script.onreadystatechange = null

            resolve()
        }

        document.head.appendChild(script)
    })
}

function jumpTo_jumpToValue(li) {
    if (jQuery("#jump_to_concept_id") == null && jQuery("#jump_to_ontology_id") == null) {
        var search = confirm("Class could not be found or is not browsable in " + BP_SITE + ".\n\nPress OK to go to the " + BP_SITE + " Search page or Cancel to try again");
        if (search) {
            document.location = BP_SEARCH_SERVER + "/search/";
            return;
        }
    }
    if (jQuery("#jump_to_concept_id") != null && jQuery("#jump_to_ontology_id") != null) {
        var sValue = jQuery("#jump_to_concept_id").val();
        var ontology_id = jQuery("#jump_to_ontology_id").val();
        document.location = BP_SEARCH_SERVER + "/ontologies/" + ontology_id + "/?p=classes&conceptid=" + encodeURIComponent(sValue);
        return;
    }
}

// Formats the Jump To search results
function jumpTo_formatItem(row) {
    var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"), // .*+?|()[]{}\
        keywords = jQuery(jumpTo_searchBoxSelector).val().trim().replace(specials, "\\$&").split(' ').join('|'),
        regex = new RegExp('(' + keywords + ')', 'gi');
    var resultTypeSpan = jQuery("<span>");
    resultTypeSpan.attr("style","font-size:9px;color:blue;");
    if (typeof row[2] !== "undefined" && row[2] !== "") {
        resultTypeSpan.text(row[2]);
    }
    if (row[0].match(regex) == null) {
        var contents = row[6].split("\t");
        var synonym = contents[0] || "";
        synonym = synonym.split(";");
        if (synonym !== "") {
            var matchSynonym = jQuery.grep(synonym, function(e) {
                return e.match(regex) != null;
            });
            row[0] = row[0] + " (synonyms: " + matchSynonym.join(", ") + ")";
        }
    }
    // Cleanup obsolete class tag before markup for search keywords.
    if (row[0].indexOf("[obsolete]") != -1) {
        row[0] = row[0].replace("[obsolete]", "");
        obsolete_prefix = "<span class='obsolete_class' title='obsolete class'>";
        obsolete_suffix = "</span>";
    } else {
        obsolete_prefix = "";
        obsolete_suffix = "";
    }
    // Markup the search keywords.
    var resultClass = row[0].replace(regex, "<b><span style='color:#006600;'>$1</span></b>");
    // Set wider class name column
    var resultClassWidth = "350px";
    if (BP_include_definitions) {
        resultClassWidth = "150px";
    } else if (BP_ontology_id == "") {
        resultClassWidth = "300px";
    }
    var resultClassDiv = jQuery("<div>");
    resultClassDiv.addClass("result_class");
    resultClassDiv.attr("style", "width: " + resultClassWidth);
    resultClassDiv.html(resultClass); // resultClass contains markup, not just text.
    var resultDiv = jQuery("<div>");
    // row[7] is the ontology_id, only included when searching multiple ontologies
    var result_ont_version = row[3],
        result_uri = row[4];
    if (BP_ontology_id !== "") {
        if (BP_include_definitions) {
            resultDiv.append(definitionDiv(result_ont_version, result_uri));
        }
        resultDiv.append(resultClassDiv);
        resultDiv.append(resultTypeSpan.attr("style", "overflow: hidden; float: none;"));
    } else {
        resultDiv.append(resultClassDiv);
        if (BP_include_definitions) {
            resultDiv.append(definitionDiv(result_ont_version, result_uri));
        }
        resultDiv.append(resultTypeSpan);
        var resultOnt = row[7];
        var resultOntDiv = jQuery("<div>");
        resultOntDiv.addClass("result_ontology");
        resultOntDiv.attr("style", "overflow: hidden;");
        resultOntDiv.text(truncateText(resultOnt, 30));
        resultDiv.append(resultOntDiv);
    }
    return obsolete_prefix + resultDiv.html() + obsolete_suffix;
}

function definitionDiv(ont, concept) {
    var definitionAjax = jQuery("<a>");
    definitionAjax.addClass("get_definition_via_ajax");
    definitionAjax.attr("href", BP_SEARCH_SERVER + "/ajax/json_class?callback=?&ontologyid=" + ont + "&conceptid=" + encodeURIComponent(concept));
    var definitionDiv = jQuery("<div>");
    definitionDiv.addClass('result_definition');
    definitionDiv.text("retreiving definitions...");
    definitionDiv.append(definitionAjax);
    return definitionDiv;
}

function jumpTo_setup_functions() {
    var extra_params = {
        subtreerootconceptid: encodeURIComponent(BP_search_branch)
    };
    var result_width = 350;
    // Add extra space for definition
    if (BP_include_definitions) {
        result_width += 300;
    }
    // Add space for ontology name
    if (BP_ontology_id === "") {
        result_width += 250;
    } else {
        result_width += 100;
    }
    jQuery(jumpTo_searchBoxSelector).bioportal_autocomplete(BP_SEARCH_SERVER + "/search/json_search/" + BP_ontology_id, {
        extraParams: extra_params,
        lineSeparator: "~!~",
        matchSubset: 0,
        minChars: 3,
        maxItemsToShow: 20,
        onFindValue: jumpTo_jumpToValue,
        onItemSelect: jumpTo_jumpToSelect,
        width: result_width,
        footer: '<div style="color: grey; font-size: 8pt; font-family: Verdana; padding: .8em .5em .3em;">Results provided by <a style="color: grey;" href="' + BP_SEARCH_SERVER + '">' + BP_ORG_SITE + '</a></div>',
        formatItem: jumpTo_formatItem
    });
    // Setup polling to get definitions
    if (BP_include_definitions) {
        getWidgetAjaxContent();
    }
}

// Poll for potential definitions returned with results
function getWidgetAjaxContent() {
    // Look for anchors with a get_via_ajax class and replace the parent with the resulting ajax call
    $(".get_definition_via_ajax").each(function() {
        var def_link = $(this);
        if (typeof def_link.attr("getting_content") === 'undefined') {
            def_link.attr("getting_content", true);
            $.getJSON(def_link.attr("href"), function(data) {
                var definition = (typeof data.definition === 'undefined') ? "" : data.definition.join(" ");
                def_link.parent().html(truncateText(decodeURIComponent(definition.replace(/\+/g, " "))));
            });
        }
    });
    setTimeout(getWidgetAjaxContent, 100);
}

// Sets a hidden form value that records the concept id when a concept is chosen in the jump to
// This is a workaround because the default autocomplete search method cannot distinguish between two
// concepts that have the same preferred name but different ids.
function jumpTo_jumpToSelect(li) {
    jQuery("#jump_to_concept_id").val(li.extra[0]);
    jQuery("#jump_to_ontology_id").val(li.extra[2]);
}

function jumpTo_jump_clicked() {
    jQuery("#BP_search_box")[0].autocompleter.findValue();
}

function truncateText(text, max_length) {
    if (typeof max_length === 'undefined' || max_length == "") {
        max_length = 70;
    }
    var more = '...';
    var content_length = $.trim(text).length;
    if (content_length <= max_length)
        return text; // bail early if not overlong
    var actual_max_length = max_length - more.length;
    var truncated_node = jQuery("<div>");
    var full_node = jQuery("<div>").html(text).hide();
    text = text.replace(/^ /, ''); // node had trailing whitespace.
    var text_short = text.slice(0, max_length);
    // Ensure HTML entities are encoded
    // http://debuggable.com/posts/encode-html-entities-with-jquery:480f4dd6-13cc-4ce9-8071-4710cbdd56cb
    text_short = $('<div/>').text(text_short).html();
    var other_text = text.slice(max_length, text.length);
    text_short += "<span class='expand_icon'><b>" + more + "</b></span>";
    text_short += "<span class='long_text'>" + other_text + "</span>";
    return text_short;
}
