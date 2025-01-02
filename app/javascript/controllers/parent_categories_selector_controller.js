import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parent-categories-selector"
export default class extends Controller {
    static targets = ['chips']
    static values = { categories: Array}

    check(event){
        const input = event.currentTarget.querySelector('input')
        const allInputs = this.chipsTarget.querySelectorAll('input')
        const parents = this.#categories_with_children()

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

    #categories_with_children(){        
        const parentToChildren = {};
        this.categoriesValue.forEach(category => {
        if (category.parentCategory) {
            category.parentCategory.forEach(parentId => {
            const parentAcronym = this.#id_to_acronym(parentId);
            const childAcronym = this.#id_to_acronym(category.id);

            if (!parentToChildren[parentAcronym]) {
                parentToChildren[parentAcronym] = [];
            }
            parentToChildren[parentAcronym].push(childAcronym);
            });
        }
        });
        return parentToChildren
    }

    #id_to_acronym(id){
        return id.split('/').pop();
    }
}