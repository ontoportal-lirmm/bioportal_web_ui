import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parent-categories-selector"
export default class extends Controller {
    static targets = ['chips']
    static values = { categoriesChildren: Object}

    check(event){
        const input = event.currentTarget.querySelector('input')
        const allInputs = this.chipsTarget.querySelectorAll('input')
        const parents = this.categoriesChildrenValue
        if(this.#id_to_acronym(input.value) in parents){
            const parentChildren = parents[this.#id_to_acronym(input.value)]
            allInputs.forEach(i => {
                if(parentChildren.includes(this.#id_to_acronym(i.value))){
                    if(input.checked){
                        i.checked = true;
                        i.dispatchEvent(new Event('change', { bubbles: true })); 
                    } else {
                        i.checked = false;
                        i.dispatchEvent(new Event('change', { bubbles: true })); 
                    }
                }
            });
        }
    }

    #id_to_acronym(id){
        return id.split('/').pop();
    }
}