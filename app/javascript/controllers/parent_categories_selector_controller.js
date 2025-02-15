import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parent-categories-selector"
export default class extends Controller {
    static targets = ['chips']
    static values = { categoriesChildren: Object, categoriesParents: Object}

    check(event) {
        const input = event.currentTarget.querySelector('input');
        const allInputs = this.chipsTarget.querySelectorAll('input');
        const parents = this.categoriesChildrenValue;
        const children = this.categoriesParentsValue;
        const browseLogic = !this.hasCategoriesParentsValue;

        // Browse page logic: 
            // - Selecting a category will auto select all its children
            // - Deselecting a category will auto deselect all its children
        // Upload/Edit forms logic: 
            // - Selecting a category will auto select its parents
            // - Deselecting a category will auto deselect its children

        const inputAcronym = this.#id_to_acronym(input.value);
    
        if (browseLogic) {
            if (inputAcronym in parents) {
                const parentChildren = parents[inputAcronym];
                this.#toggleInputState(allInputs, i => parentChildren.includes(this.#id_to_acronym(i.value)), input.checked);
            }
        } else {
            if (inputAcronym in parents) {
                const parentChildren = parents[inputAcronym];
                this.#toggleInputState(allInputs, i => parentChildren.includes(this.#id_to_acronym(i.value)), false);
            }
            if (inputAcronym in children) {
                const childParents = children[inputAcronym];
                this.#toggleInputState(allInputs, i => childParents.includes(this.#id_to_acronym(i.value)), true);
            }
        }
    }

    #toggleInputState(inputs, condition, state) {
        inputs.forEach(input => {
            if (condition(input)) {
                input.checked = state;
                input.dispatchEvent(new Event('change', { bubbles: true }));
            }
        });
    }

    #id_to_acronym(id){
        return id.split('/').pop();
    }
}