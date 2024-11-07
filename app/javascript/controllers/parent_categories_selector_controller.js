import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parent-categories-selector"
export default class extends Controller {
    static targets = ['chips']
    static values = { categories: Array}

    check(event){
        const input = event.currentTarget.querySelector('input')
        const allInputs = this.chipsTarget.querySelectorAll('input')
        const children = this.#categories_with_parents()
        const parents = this.#categories_with_children(children)
        
        if(input.value in parents){
            const parentChildren = parents[input.value]
            allInputs.forEach(i => {
                if(parentChildren.includes(i.value) && !input.checked){
                    i.checked = false;
                    i.dispatchEvent(new Event('change', { bubbles: true })); 
                }

            });
        }
        if(input.value in children){
            const childParents = children[input.value]
            allInputs.forEach(i => {
                if(childParents.includes(i.value) && input.checked){
                    i.checked = true;
                    i.dispatchEvent(new Event('change', { bubbles: true })); 
                }
            });
        }
    }

    #categories_with_parents() {
        const children = {};
        this.categoriesValue.forEach(category => {
            if (category.parentCategory.length > 0) {
                const parentsAcronyms = category.parentCategory.map(p => p.split('/').pop());
                children[category.acronym] = parentsAcronyms;
            }
        });
        return children;
    }

    #categories_with_children(children){
        const parents = {};
        Object.keys(children).forEach(child => {
            children[child].forEach(parent => {
                if (!parents[parent]) {
                    parents[parent] = [];
                }
                parents[parent].push(child);
            });
        });
        return parents
    }
}