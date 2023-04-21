import {Controller} from "@hotwired/stimulus";
import useAjax from "../../javascript/mixins/useAjax";

// Connects to data-controller="subscribe-notes"
export default class extends Controller {
    static values = {
        ontologyId: String,
        isSubbed: Boolean,
        userId: String
    }
    static targets = ["error", "loader"]

    subscribeToNotes() {
        let ontologyId = this.ontologyIdValue
        let isSubbed = this.isSubbedValue
        let userId = this.userIdValue

        this.#hideError()
        this.#showSpinner()

        let url = "/subscriptions?user_id=" + userId + "&ontology_id=" + ontologyId + "&subbed=" + isSubbed;
        useAjax({
            type: "POST",
            url: url,
            dataType: "json",
            success: () => {
                // Change subbed value on a element
                this.#hideSpinner()
                let linkElement = $(this.element);
                this.isSubbedValue = !isSubbed

                // Change button text
                let txt = linkElement.html();
                let newButtonText = txt.match("Unsubscribe") ? txt.replace("Unsubscribe", "Subscribe") : txt.replace("Subscribe", "Unsubscribe");
                linkElement.html(newButtonText);
            },
            error: () => {
                this.#hideSpinner()
                this.#showError()
            }
        })
    }

    #showSpinner() {
        $(this.loaderTarget).show()
    }

    #hideSpinner() {
        $(this.loaderTarget).hide()
    }


    #showError() {
        const errorElem = $(this.errorTarget)
        errorElem.html("Problem subscribing to emails, please try again")
        errorElem.show()
    }

    #hideError() {
        $(this.errorTarget).hide()
    }


}
