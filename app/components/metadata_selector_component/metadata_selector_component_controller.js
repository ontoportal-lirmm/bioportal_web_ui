import {Controller} from "@hotwired/stimulus";
import {useChosen} from "../../javascript/mixins/useChosen";

export default class extends Controller {
    connect() {
        useChosen(this.element, {
            search_contains: true,
            width: "100%"
        }, this.#triggerChange.bind(this))
    }

    #triggerChange() {
        document.dispatchEvent(new Event('change', {target: this.element}))
    }
}
