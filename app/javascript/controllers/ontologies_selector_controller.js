import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['submit', 'ontology', 'table']
    input(){
        this.submitTarget.click()
    }
    change(event){
        this.submitTarget.click()
        this.#updateTableNumbers(event)
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
    #updateTableNumbers(){
        let navItems = this.tableTarget.querySelectorAll('.nav-item')
        for (var i = 0; i < navItems.length; i++) {
            this.#updateNavItemCount(navItems[i])
        }        
    }
    #updateNavItemCount(navItem){
        let tabPane = this.tableTarget.querySelector('.tab-pane'+navItem.getAttribute('data-target'))
        let inputs = tabPane.querySelectorAll('input')
        let count = 0
        for (var i = 0; i < inputs.length; i++) {
            if (inputs[i].checked){
                count++;
            }
        } 
        let itemTitle = navItem.querySelector('a').innerHTML 
        let regex = /\(\d+\)/;
        if (itemTitle.endsWith(")")){
            
            navItem.querySelector('a').innerHTML = itemTitle.replace(regex, '(' + count + ')');
        } else {
            navItem.querySelector('a').innerHTML = `${itemTitle} (${count})`;
        }

        if (count==0){
            navItem.querySelector('a').innerHTML = itemTitle.replace(regex, '').trim();
        }
    }    
}