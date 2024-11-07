import OntoportalAutocompleteController from "./ontoportal_autocomplete_controller";

// Connects to data-controller="class-search"
export default class extends OntoportalAutocompleteController {
    static values = {
        spinnerSrc: String
    }
    connect() {
        super.connect()
    }

    onFindValue(li) {
        if (li == null) {
            // No result found
            // TODO in this case show a message to redirect to the global search page
            return
        }

        // Appropriate value selected
        if (li.extra) {
            let sValue = jQuery("#jump_to_concept_id").val()
            Turbo.visit("/ontologies/" + jQuery(document).data().bp.ontology.acronym + "/?p=classes&conceptid=" + encodeURIComponent(sValue) + "&jump_to_nav=true")
        }
    }

    onItemSelect(li) {
        jQuery("#jump_to_concept_id").val(li.extra[0]);
        this.onFindValue(li);
    }
}
