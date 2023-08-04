import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
    connect() {
        let myOptions = {}
        if (this.data.get("multipleValue")) {
            myOptions['plugins'] = ['remove_button'];
        }
        if (this.data.get("openAddValue")) {
            myOptions['create'] = true;
        }
        new TomSelect(this.element, myOptions);
    }

}