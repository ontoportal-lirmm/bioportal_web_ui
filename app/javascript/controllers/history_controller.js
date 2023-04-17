import {Controller} from "@hotwired/stimulus"
import {HistoryService} from "../mixins/useHistory";

// Connects to data-controller="history"
export default class extends Controller {
    connect() {
        this.history = new HistoryService()
    }
    updateURL(event) {
        const newData = event.detail.data
        if (newData !== undefined) {
            this.history.updateHistory(document.location.pathname + document.location.search, newData)
        }
    }


}
