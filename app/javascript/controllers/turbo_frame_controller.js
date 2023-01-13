import {Controller} from "@hotwired/stimulus"
import {HistoryService} from "../mixins/useHistory";

// Connects to data-controller="turbo-frame"
export default class extends Controller {
    static values = {
        url: String,
        placeHolder: {type: String, default: 'Nothing loaded'},
    }
    static targets = ['frame']

    connect() {
        this.frame = this.frameTarget
    }

    updateFrame(event) {
        const newData = event.detail.data
        const values = Object.entries(newData)[0][1]
        if (values.filter(x => x.length !== 0).length === 0) {
            this.frame.innerHTML = this.placeHolderValue
        } else {
            this.frame.innerHTML = ""
            this.urlValue = new HistoryService().getUpdatedURL(this.urlValue, newData);
            this.frame.src = this.urlValue
        }
    }
}
