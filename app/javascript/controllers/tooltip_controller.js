import {Controller} from "@hotwired/stimulus"
import useTooltip from "../mixins/useTooltip";

// Connects to data-controller="tooltip"
export default class extends Controller {

    static values = {
        position: {type: String, default: 'top'},
        interactive: {type: Boolean, default: false}
    }

    connect() {
        if (this.element.title && this.element.title !== '') {
            useTooltip(this.element, {interactive: this.interactiveValue, placement: this.positionValue})
        }

    }

}
