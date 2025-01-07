import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parent-categories-selector"
export default class extends Controller {
    static targets = ['chips']
    static values = { categoriesChildren: Object, categoriesParents: Object}

    check(event){
        const input = event.currentTarget.querySelector('input')
        const allInputs = this.chipsTarget.querySelectorAll('input')
        const parents = this.categoriesChildrenValue
        const children = this.categoriesParentsValue
        const browse_logic = !this.hasCategoriesParentsValue

        if(browse_logic){
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
        } else {
            if(this.#id_to_acronym(input.value) in parents){
                const parentChildren = parents[this.#id_to_acronym(input.value)]
                allInputs.forEach(i => {
                    if(parentChildren.includes(this.#id_to_acronym(i.value)) && !input.checked){
                        i.checked = false;
                        i.dispatchEvent(new Event('change', { bubbles: true })); 
                    }
    
                });
            }
            if(this.#id_to_acronym(input.value) in children){
                const childParents = children[this.#id_to_acronym(input.value)]
                allInputs.forEach(i => {
                    if(childParents.includes(this.#id_to_acronym(i.value)) && input.checked){
                        i.checked = true;
                        i.dispatchEvent(new Event('change', { bubbles: true })); 
                    }
                });
            }
        }
    }

    #id_to_acronym(id){
        return id.split('/').pop();
    }
}