import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="sample-text"
export default class extends Controller {
    static targets = ['input']
    annotator_recommender(event){
        let button = event.target.closest("[data-sample-text]");
        this.inputTarget.value = button.dataset.sampleText
    }
}