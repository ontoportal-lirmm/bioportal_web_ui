import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="labels-ajax-container"
export default class extends Controller {
    static outlets = ['label-ajax']

    abortAll() {
        this.labelAjaxOutlets.forEach((link) => {link.abort()})
    }
}
