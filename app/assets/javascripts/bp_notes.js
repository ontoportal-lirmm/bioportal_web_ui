function hideOrUnhideArchivedOntNotes() {
  if (jQuery("#hide_archived_ont:checked").val() !== undefined) {
    // Checked
    ontNotesTable.fnFilter('false', ont_columns.archived);
  } else {
    // Unchecked
    ontNotesTable.fnFilter('', ont_columns.archived, true, false);
  }
}

function wireOntTable(ontNotesTableNew, showTarget= true, enableDelete = false) {
  jQuery.data(document.body, "ontology_id", "#{@ontology.acronym}");


  let ont_columns = { archived: 3, date: 7, subjectSort: 2 };
  var ontNotesTable = ontNotesTableNew;
  let columns =  [
    { "bVisible": enableDelete }, // Delete
    { "iDataSort": ont_columns.subjectSort }, // Subject link
    { "bVisible": false }, // Subject for sort
    { "bVisible": false }, // Archived for filter
    null, // Author
    null, // Type
    null // Created
  ]

  if(showTarget){
    columns.push(null) // Target
  }else {
    ont_columns.date--
  }

  ontNotesTable.dataTable({
    "iDisplayLength": 50,
    "sPaginationType": "full_numbers",
    "aaSorting": [[ont_columns.date, 'desc']],
    "aoColumns": columns,
  });
  // Important! Table is somehow getting set to zero width. Reset here.
  jQuery(ontNotesTable).css("width", "100%");
  ontNotesTable.fnFilter('false', ont_columns.archived);
}
