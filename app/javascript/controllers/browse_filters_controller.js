import {Controller} from "@hotwired/stimulus"
import debounce from "debounce"
// Connects to data-controller="browse-filters"
export default class extends Controller {

    initialize() {
        this.dispatchInputEvent = debounce(this.dispatchInputEvent.bind(this), 700);
    }

    dispatchInputEvent(event) {
        let value
        if (event.target instanceof HTMLSelectElement) {
            value = Array.from(event.target.selectedOptions).map(x => x.value)
        } else {
            value = [event.target.value]
        }

        this.#dispatchEvent(event.target.name, value)
    }

    dispatchFilterEvent(event) {
        let checks;
        let filter;

        switch (event.target.name) {
            case "format":
                checks = event.target.value === '' ? [] : [event.target.value]
                filter = "format"
                break;
            case "Sort_by":
                checks = [event.target.value]
                filter = "sort_by"
                break;
            case "search":
                return
            case "views":
                checks = event.target.checked ?  ['true'] : []
                filter = "show_views"
                break;
            case "retired":
                checks = event.target.checked ?  ['true'] : []
                filter = "show_retired"
                break;
            case "private_only":
                checks = event.target.checked ?  ['true'] : []
                filter = "private_only"
                break;
            default:
                checks = this.#getSelectedChecks().map(x => x.value)
                filter = event.target.name
        }

        this.#dispatchEvent(filter, checks)
    }


    #dispatchEvent(filter, checks){
        let data = {
            [filter]: checks,
        }
        const customEvent = new CustomEvent('changed', {
            detail: {
                data: data
            }, bubbles: true
        });

        this.element.dispatchEvent(customEvent);
    }
    #getSelectedChecks() {
        return Array.from(this.element.querySelectorAll('input:checked'))
    }

}
