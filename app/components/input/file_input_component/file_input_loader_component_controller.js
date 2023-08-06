import {Controller} from "@hotwired/stimulus";

// Connects to data-controller="file-input"
export default class extends Controller {

    static targets = [ "input", "message" ]

    updateMessage(){
        const fileName = this.inputTarget.value.split('\\').pop()
        this.messageTarget.innerHTML = fileName
    }


}