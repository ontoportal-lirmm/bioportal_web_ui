import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['submit', 'ontology']
    input(){
        this.submitTarget.click()
    }
    change(){
        this.submitTarget.click()
    }
    selectall(event){
        if (event.target.innerHTML == '\nselect all\n'){
            for (var i = 0; i < this.ontologyTargets.length; i++) {
                this.ontologyTargets[i].querySelector('input').checked = true
            }
            event.target.innerHTML = '\nunselect all\n'
        } else {
            for (var i = 0; i < this.ontologyTargets.length; i++) {
                this.ontologyTargets[i].querySelector('input').checked = false
            }
            event.target.innerHTML = '\nselect all\n'
        }
        
    }
}