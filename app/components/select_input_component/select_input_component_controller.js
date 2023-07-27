import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
    
    connect() {
        // console.log(this.data.get("multipleValue"))
        new TomSelect(this.element, {


            //plugins: ['remove_button']
        });
    }

}