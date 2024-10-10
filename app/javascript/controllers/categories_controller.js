import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="categories"
export default class extends Controller {
    static targets = ['chips']
    static values = { categories: Array}
    check(event){
        const input = event.currentTarget.querySelector('input')
        const parents = this.#nest_children_inside_parents()
        if(input.value in parents){
            const allInputs = this.chipsTarget.querySelectorAll('input')
            const children = parents[input.value]
            allInputs.forEach(i => {
                if(children.includes(i.value)){
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
    #nest_children_inside_parents(){
        const parents = this.categoriesValue.reduce((acc, category) => {
            if (category.parentCategory.length > 0) {
                category.parentCategory.forEach(parent => {
                    const parentAcronym = parent.split('/').pop();
                    if (!acc[parentAcronym]) {
                        acc[parentAcronym] = [];
                    }
                    acc[parentAcronym].push(category.acronym);
                });
            }
            return acc;
        }, {});
        return parents
    }

}