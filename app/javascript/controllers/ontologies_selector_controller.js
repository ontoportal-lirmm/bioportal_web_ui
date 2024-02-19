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
    selectall(event) {
        const selectText = '\nselect all\n';
        const unselectText = '\nunselect all\n';
        const isChecked = event.target.innerHTML === unselectText;
        const newInnerHTML = isChecked ? selectText : unselectText;
        for (const target of this.ontologyTargets) {
            target.querySelector('input').checked = !isChecked;
        }
        event.target.innerHTML = newInnerHTML;
    }
    #updateTableNumbers() {
        const navItems = Array.from(this.tableTarget.querySelectorAll('.nav-item'));
        navItems.forEach(item => this.#updateNavItemCount(item));
    }
    
    #updateNavItemCount(navItem) {
        const tabPane = this.tableTarget.querySelector(`.tab-pane${navItem.getAttribute('data-target')}`);
        const inputs = tabPane.querySelectorAll('input');
        const count = Array.from(inputs).filter(input => input.checked).length;
        const itemTitleElement = navItem.querySelector('a');
        let itemTitle = itemTitleElement.innerHTML.trim();
        const regex = /\(\d+\)/;
        if (itemTitle.endsWith(")")) {
            itemTitleElement.innerHTML = itemTitle.replace(regex, `(${count})`);
        } else {
            itemTitleElement.innerHTML = `${itemTitle} (${count})`;
        }
        if (count === 0) {
            itemTitleElement.innerHTML = itemTitle.replace(regex, '').trim();
        }
    }  
}