import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="doi-request"
export default class extends Controller {
    connect() {
    }

    cancel() {
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
                    success: function (data) {
                        alert("The request was canceled!");
                        let html_identifier = `
                  <div class="margin-top-10px">
                      <div id="div-cb-require-doi">
                        <input id="doi_request" name="submission[is_doi_requested]" type="checkbox">
                        <label for="doi_request">Check this box if your asset has no PID and you want to request a DOI</label>
                      </div>
                  </div>`;
                        $("#identifier_fields_col").html(html_identifier)
                    },
                    error: function (data) {
                        alert("An Error has occurred. The request cannot be canceled");
                    }
                });
            } else {
                alert("WARNING! The request ID is not defined. The request cannot be canceled")
            }
        }
    }
}
