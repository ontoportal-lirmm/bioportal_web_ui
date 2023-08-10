import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

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
        new TomSelect(this.element, myOptions);
    }

}