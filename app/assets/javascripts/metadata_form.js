$(document).ready(function(){
  // updateIdentifierType();
  $("#submission_identifierType").change(function(e){
    // updateIdentifierType();
  });

  let btn_cancel_request = $(".btn_cancel_request")
  if (btn_cancel_request.length) {
    btn_cancel_request.click(function(e){
      cancelDoiRequest()
      e.preventDefault()
    });
  }
});



/////////////// IDENTIFIER /////////////////////
function updateIdentifierType() {
  let value = $("#submission_identifierType").val();
  disableById('submission_identifier');
  hideElementById('div-cb-require-doi');
  hideElementById('button-load-by-doi');
  $("#doi_request").prop( "checked", false );
  if (typeof value !== 'undefined'){
    switch (value.toLowerCase()) {
      case 'none':      
        showElementById('div-cb-require-doi');
        $("#submission_identifier").val('')
        break;
      case 'doi':      
        enableById('submission_identifier');
        showElementById('button-load-by-doi')
        break;
      case 'other':
        enableById('submission_identifier');
        break;
    }
  }
}

function cancelDoiRequest(){
  let resp_Yes = confirm("Do you want to cancel the DOI request?")
  if (resp_Yes) {
    let btn_cancel_selector = $(".btn_cancel_request")
    let req_id = btn_cancel_selector[0].id.split("-")[1]
    if (req_id) {
      //ajax call to cancel the request
      let URL = '/ajax/cancelIdentifierRequest'
      jQuery.ajax({
        type: "POST",
        url: URL,
        data: {
          requestId: req_id,
          status: "CANCELED"
        },
        dataType: "json",
        success: function(data) {
          alert("The request was canceled!");
          let html_identifier = `
                  <div class="margin-top-10px">
                      <div id="div-cb-require-doi">
                        <input id="doi_request" name="submission[is_doi_requested]" type="checkbox">
                        <label for="doi_request">Check this box if your asset has no PID and you want to request a DOI</label>
                      </div>
                  </div>`;
          $("#identifier_fields_col").html(html_identifier)
          $("#submission_identifierType").change(function(e){
            updateIdentifierType();
          });
        },
        error: function(data) {
          alert( "An Error has occurred. The request cannot be canceled");
        }
      });
    } else {
      alert("WARNING! The request ID is not defined. The request cannot be canceled")
    }
  }
}
///////////// UTILS ////////////


/**
 * disable the element by Id and all its children
 * @param {*} id 
 */
function disableById(id){
  let elem =  $("#" + id);
  elem.prop("disabled", true); //.addClass('disabled');
  if(elem.children().length) {
    elem.children().prop("disabled", true);
  }
}

function enableById(id){
  let elem =  $("#" + id);
  elem.prop("disabled", false);
  if(elem.children().length) {
    elem.children().prop("disabled", false);
  }
}

function hideElementById(id){
  $("#" + id).hide();
}

function showElementById(id){
  $("#" + id).show();
}


$.escapeSelector = function (txt) {
  return txt.replace(
      /([$%&()*+,./:;<=>?@\[\\\]^\{|}~])/g,
      '\\$1'
  );
};