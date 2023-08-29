import { Controller } from "@hotwired/stimulus"
import {useTomSelect} from "../../javascript/mixins/useTomSelect";

export default class extends Controller {
    static values = {
        multiple: Boolean,
        openAdd : Boolean
    }
    connect() {
        let myOptions = {}
        if (this.multipleValue) {
            myOptions['plugins'] = ['remove_button'];
        }
        if (this.openAddValue) {
            myOptions['create'] = true;
        }

        useTomSelect(this.element, myOptions, this.#triggerChange.bind(this))
    }

    #triggerChange() {
        document.dispatchEvent(new Event('change', { target: this.element }))
    }
}