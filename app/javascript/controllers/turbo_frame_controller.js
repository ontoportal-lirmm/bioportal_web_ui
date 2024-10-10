import { Controller } from "@hotwired/stimulus"
import { HistoryService } from "../mixins/useHistory";

// Connects to data-controller="turbo-frame"
export default class extends Controller {
    static values = {
        url: String,
        placeHolder: { type: String, default: 'Nothing loaded' },
    }
    static targets = ['frame']

    connect() {
        this.frame = this.frameTarget
    }

    updateFrame(event) {
        const { data } = event.detail
        const values = Object.values(data)

        // remove null and empty values
        values.filter((value) => value !== "" || value !== undefined)

        if (values.length === 0) {
            this.frame.innerHTML = this.placeHolderValue
        } else {
            this.frame.innerHTML = ""
            this.urlValue = new HistoryService().getUpdatedURL(this.urlValue, data)
            this.frame.src = this.urlValue
        }
    }
}
