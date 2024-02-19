import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['submit', 'ontology']
    input(){
        this.submitTarget.click()
    }
    change(){
        this.submitTarget.click()
    }
    selectall(){
        for (var i = 0; i < this.ontologyTargets.length; i++) {
            this.ontologyTargets[i].querySelector('input').checked = true
        }
    }
}