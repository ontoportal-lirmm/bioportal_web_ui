
// Generate the used engineering tools tag cloud
$(document).ready(function() {
    // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
    $("#toolCloudChart").jQCloud(landscapeData["engineering_tool_cloud_json"]);

    // Generate the people tag cloud (from all contributors attributes)
    // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
    $("#peopleCloudChart").jQCloud(landscapeData["people_count_json_cloud"]);

    // Generate the organization tag cloud (from fundedBy, endorsedBy...), don't show if less than 5 words
    // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
    $("#orgCloudChart").jQCloud(landscapeData["org_count_json_cloud"]);

    // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
    $("#notesPeopleCloudChart").jQCloud(landscapeData["notes_people_json_cloud"]);

    // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
    $("#notesOntologiesCloudChart").jQCloud(landscapeData["notes_ontologies_json_cloud"]);


});

/**
 * To show/hide the simple metadata div
 */
function toggleDiv(divId)
{
  var e = document.getElementById(divId + "Div");
  if (e.style.display == 'block') {
    e.style.display = 'none';
    document.getElementById(divId + "Btn").classList.remove("active");
  } else {
    e.style.display = 'block';
    document.getElementById(divId + "Btn").classList.add("active");
  }
}

var chartTooltipLocked = false;

// Creating a pie chart using d3pie.js
// function to generate a pie chart given 4 simple params: the div class name (the html div where the pie chart will go)
// the JSON containing the chart data. groupSmall is a boolean to define if we want to group small values
var createPie = function(divName, json, groupSmall) {
    new d3pie(divName, {
        "footer": {
            "color": "#999999",
            "fontSize": 10,
            "font": "open sans",
            "location": "bottom-left"
        },
        "size": {
            "canvasWidth": document.getElementById(divName).offsetWidth,
            //"canvasHeight": 300,
            "pieOuterRadius": "50%"
        },
        "data": {
            "sortOrder": "value-desc",
            "smallSegmentGrouping": {
              "enabled": groupSmall,
              "value": 5
              // To group small pie value as Other
            },
            "content": json
        },
        callbacks: {
          onMouseoverSegment: function (d) {
            if (chartTooltipLocked == false) {
              d3.select("#chartTooltip")
                .style("left", d3.event.pageX + "px")
                .style("top", d3.event.pageY + "px")
                .style("opacity", 1)
                .style("z-index", 1)
              d3.select("#chartTooltipValue")
                .text(d.data.uri);
              // Don't show tooltip when text is empty (for Others)
              if (d.data.uri) {
                $("#chartTooltip").show();
              }
            }
            if (!d.data.uri) {
              $("#chartTooltip").hide();
            }
          },
          onClickSegment: function(d) {
            //dbIds: d.expanded? [] : d.data.dbIds
            var wasLocked = chartTooltipLocked
            if (d.expanded) {
              dbIds = []
              chartTooltipLocked = false;
            } else {
              dbIds = d.data.dbIds
              chartTooltipLocked = true;
            }

            if (wasLocked == true) {
              d3.select("#chartTooltip")
                .style("left", d3.event.pageX + "px")
                .style("top", d3.event.pageY + "px")
                .style("opacity", 1)
              d3.select("#chartTooltipValue")
                .text(d.data.uri);
              if (d.data.uri) {
                $("#chartTooltip").show();
              }
            }
          },
          onMouseoutSegment: function(info) {
            //$("#chartTooltip").hide(); this avoid us to mouseover tooltip text
          }
        },
        "labels": {
            "truncation": {
              "enabled": true,
              "truncateLength": 40
            },
            "outer": {
                "pieDistance": 15
            },
            "inner": {
                "hideWhenLessThanPercentage": 5
            },
            "mainLabel": {
                "fontSize": 11
            },
            "percentage": {
                "color": "#ffffff",
                "decimalPlaces": 0
            },
            "value": {
                "color": "#adadad",
                "fontSize": 11
            },
            "lines": {
                "enabled": true
            }
        },
        "effects": {
            "pullOutSegmentOnClick": {
                "effect": "linear",
                "speed": 400,
                "size": 8
            }
        },
        "misc": {
            "gradient": {
                "enabled": true,
                "percentage": 100
            }
        }
    })
}

// To create a new pie chart: add "%div#prefLabelPieChartDiv" to html and use the createPie function
var naturalLanguagePie = createPie("naturalLanguagePieChartDiv", landscapeData["natural_language_json_pie"], true);

var licensePie = createPie("licensePieChartDiv", landscapeData["licenseProperty_json_pie"], true);

var prefLabelPie = createPie("prefLabelPropertyPieChartDiv", landscapeData["prefLabelProperty_json_pie"], false);

var synonymPie = createPie("synonymPropertyPieChartDiv", landscapeData["synonymProperty_json_pie"], false);

var definitionPie = createPie("definitionPropertyPieChartDiv", landscapeData["definitionProperty_json_pie"], false);

var authorPie = createPie("authorPropertyPieChartDiv", landscapeData["authorProperty_json_pie"], false);



//console.log(landscapeData);

// Generate the bar charts options by passing the tooltip callback JSON
var barChartOptions = function(tooltip_callbacks = {}) {
  return {
    scales: {
      yAxes: [{
        stacked: true
      }]
    },
    legend: {
      display: false
    },
    tooltips: {
      // put our own infos in the tooltip (see group_tooltip_callbacks)
      callbacks: tooltip_callbacks
    }
  }
}

// Creating bar charts using http://www.chartjs.org/docs/
// Horizontal bar charts for format (OWL, SKOS, UMLS)
var ontologyFormatsContext = document.getElementById("formatCanvas").getContext("2d");
var ontologyFormatsChart = new Chart(ontologyFormatsContext, {
  type: 'horizontalBar',
  data: landscapeData["ontologyFormatsChartJson"],
  options: barChartOptions()
});

// Horizontal bar charts for ontologies types
// Replace the omv prefix for values (only that for isOfType, make it faster). Be careful it's on yLabel
var ifOfTypeTooltipCallbacks = {
  title: function (tooltipItem, data) {
    return tooltipItem[0].yLabel.replace("omv:", "http://omv.ontoware.org/2005/05/ontology#");
  }
};
var isOfTypeContext = document.getElementById("isOfTypeCanvas").getContext("2d");
var isOfTypeChart = new Chart(isOfTypeContext, {
  type: 'horizontalBar',
  data: landscapeData["isOfTypeChartJson"],
  options: barChartOptions(ifOfTypeTooltipCallbacks)
});

// Vertical bar charts for ontologies formality levels
// Replace the nkos prefix for nkos values (only that for formality, make it faster)
var formalityTooltipCallbacks = {
  title: function (tooltipItem, data) {
    return tooltipItem[0].xLabel.replace("nkost:", "http://w3id.org/nkos/nkostype#");
  }
};
var formalityLevelContext = document.getElementById("formalityLevelCanvas").getContext("2d");
var formalityLevelChart = new Chart(formalityLevelContext, {
  type: 'bar',
  data: landscapeData["formalityLevelChartJson"],
  options: barChartOptions(formalityTooltipCallbacks)
});

// Vertical bar charts for ontologies formality levels
var dataCatalogContext = document.getElementById("dataCatalogCanvas").getContext("2d");
var dataCatalogChart = new Chart(dataCatalogContext, {
  type: 'bar',
  data: landscapeData["dataCatalogChartJson"],
  options: barChartOptions()
});

// Generate group bar chart
var groupTooltipCallbacks = {
  title: function (tooltipItem, data) {
    return landscapeData["groupsInfoHash"][tooltipItem[0].xLabel]["name"];
  },
  beforeBody: function (tooltipItem, data) {
    return landscapeData["groupsInfoHash"][tooltipItem[0].xLabel]["description"];
  }
};
var groupCountContext = document.getElementById("groupsCanvas").getContext("2d");
var groupCountChart = new Chart(groupCountContext, {
  type: 'bar',
  data: landscapeData["groupCountChartJson"],
  options: barChartOptions(groupTooltipCallbacks)
});



// Generate domain bar chart
var domainTooltipCallbacks = {
  title: function (tooltipItem, data) {
    return landscapeData["domainsInfoHash"][tooltipItem[0].xLabel]["name"];
  },
  beforeBody: function (tooltipItem, data) {
    return landscapeData["domainsInfoHash"][tooltipItem[0].xLabel]["description"];
  }
};
var domainCountContext = document.getElementById("domainCanvas").getContext("2d");
var domainCountChart = new Chart(domainCountContext, {
  type: 'bar',
  data: landscapeData["domainCountChartJson"],
  options: barChartOptions(domainTooltipCallbacks)
});


var sizeSlicesContext = document.getElementById("sizeSlicesCanvas").getContext("2d");
var sizeSlicesChart = new Chart(sizeSlicesContext, {
  type: 'bar',
  data: landscapeData["sizeSlicesChartJson"],
  options: barChartOptions()
});


var ontologyRelationsArray = landscapeData["ontology_relations_array"];
buildNetwork(ontologyRelationsArray);

/**
 * Build the VIS network for ontologies relations: http://visjs.org/docs/network/
 * @param ontologyRelationsArray
 */
function buildNetwork(ontologyRelationsArray) {
  var nodes = new vis.DataSet([]);
  // create an array with edges
  var edges = new vis.DataSet();
  var propertyCount = 1; // To define nodes IDs

  // Hash with nodes id for each ontology URI
  var nodeIds = {};

  /* Get the relations that have been selected
  if (jQuery("#selected_relations").val() !== null) {
    selected_relations = jQuery("#selected_relations").val()
  }*/

  var selected_relations = [];
  $("input[name='selectedRelations[]']:checked").each(function ()
  {
    selected_relations.push($(this).val());
  });

  // Iterate through all the ontology relations and add them to the network
  for (var i = 0; i < ontologyRelationsArray.length; i++) {
    // If relations have been selected for filtering then we don't show others relations
    if (jQuery("#selected_relations").val() !== null) {
      if (!selected_relations.includes(ontologyRelationsArray[i]["relation"])) {
        continue;
      }
    }
    // Don't create a new node if node exist already, just add a new edge
    if (nodeIds[ontologyRelationsArray[i]["source"]] != null) {
      var sourceNodeNumber = nodeIds[ontologyRelationsArray[i]["source"]];
    } else {
      var sourceNodeNumber = propertyCount;
      // If the node is the source it means it is from the Portal, so we colorate it in green
      nodes.add([
        {id: sourceNodeNumber, label: ontologyRelationsArray[i]["source"], color: "#5cb85c"}
      ]);
      nodeIds[ontologyRelationsArray[i]["source"]] = propertyCount;
      propertyCount++;
    }

    // Create the target node if don't exist
    if (nodeIds[ontologyRelationsArray[i]["target"]] != null) {
      var targetNodeNumber = nodeIds[ontologyRelationsArray[i]["target"]];
    } else {
      var targetNodeNumber = propertyCount;
      // If target node is an ontology from the portal then node in green
      if (ontologyRelationsArray[i]["targetInPortal"] == true) {
        nodes.add([
          {id: targetNodeNumber, label: ontologyRelationsArray[i]["target"], color: "#5cb85c"}
        ]);
      } else {
        nodes.add([
          {id: targetNodeNumber, label: ontologyRelationsArray[i]["target"]}
        ]);
      }
      nodeIds[ontologyRelationsArray[i]["target"]] = propertyCount;
      propertyCount++;
    }

    // Create edge with prefixed predicate when possible
    edges.add([
      {from: sourceNodeNumber, to: targetNodeNumber, label: ontologyRelationsArray[i]["relation"], font: {align: 'horizontal'}}
    ]);
  }


  // create a network
  var container = document.getElementById("ontologyNetwork");
  // provide the data in the vis format
  var data = {
    nodes: nodes,
    edges: edges
  };
  // Get height of div
  var networkHeight = document.getElementById("networkContainer").clientHeight.toString();

  var options = {
    autoResize: true,
    height: networkHeight,
    groups:{
      useDefaultGroups: true,
      myGroupId:{
        /*node options*/
      }
    },
    edges:{
      color:{inherit:'both'},
      smooth: {
        enabled: true,
        type: "dynamic",
        roundness: 0.5
      }
    },
    nodes: {
      shape: "box"
    },
    physics: {
      // http://visjs.org/docs/network/physics.html
      enabled: true,
      // To stabilize faster, increase the minVelocity value
      minVelocity: 1,
      stabilization: {
        enabled: true,
        onlyDynamicEdges: false,
        fit: true
      },
      barnesHut: {
        gravitationalConstant: -1500,
        centralGravity: 0,
        springLength: 300,
        springConstant: 0.01,
        damping: 0.2,
        avoidOverlap: 0.2
      },
      hierarchicalRepulsion: { // not used at the moment
        centralGravity: 0.0,
        springLength: 500,
        springConstant: 0.2,
        damping: 1,
        nodeDistance: 170
      },
      solver: 'barnesHut'
    }
    /*configure: {
      enabled: true,
      showButton: true
    }
    interaction:{
      zoomView:false,
      dragView: false
    }*/
  };

  // initialize your network!
  var network = new vis.Network(container, data, options);
  network.fit();
}

// Hide tooltip when click outside of pie chart div
$(document).mouseup(function (e)
{
  var container = $("#pieChartDiv");
  if (!container.is(e.target) // if the target of the click isn't the container...
    && container.has(e.target).length === 0) // ... nor a descendant of the container
  {
    chartTooltipLocked = false;
    $("#chartTooltip").hide();
  }
});

jQuery(document).ready(function() {
  "use strict";
  // enable selected search
  jQuery("#selected_relations").chosen({
    search_contains: true
  });
})

// Hide more properties pie div on load to let the pie lib the time to get the parent div size (to size the pie chart)
window.onload = function() {
  $("#propertiesDiv").hide();
};