var projectsTable;

jQuery(document).ready(function() {

  projectsTable = jQuery("#projects").dataTable({
    "bAutoWidth": false,
    "bLengthChange": false,
    "bFilter": false,
    "bInfo": false,
    "bPaginate": false,
    "asStripClasses":["","alt"],
    "fnDrawCallback": function(oSettings) {
      // Fix IE whitespace bug in table by removing whitespace
      // See: http://datatables.net/forums/discussion/5481/bug-ghost-columns-when-generating-large-tables
      if (navigator.appName == 'Microsoft Internet Explorer') {
        var expr = new RegExp('>[ \t\r\n\v\f]*<', 'g');
        var tbhtml = jQuery('#projects').children("tbody").html();
        jQuery('#projects').children("tbody").html(tbhtml.replace(expr, '><'));
      }
    }
  });

  // Set the table width after it gets altered by jQuery DataTable
  jQuery("#projects").css("width","100%");

  jQuery('#projects-help').on("click", bpPopWindow);

});

function descriptionDialog(title, body) {
  jQuery("#DescriptionDialog").text(body);
  jQuery("#DescriptionDialog").css("display:block")
  jQuery("#DescriptionDialog").dialog({ dialogClass: "alert" });
}

