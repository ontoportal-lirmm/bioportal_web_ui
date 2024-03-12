import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['submit', 'ontology', 'table', 'exit']
    static values = {
        id: String,
        selectAll: String,
        unselectAll: String
      }
    input(){
        this.submitTarget.click()
    }
    change(event){
        this.submitTarget.click()
        this.#updateTableNumbers(event)
    }
    selectall(event) {
        const selectText = `\n${this.selectAllValue}\n`;
        const unselectText = `\n${this.unselectAllValue}\n`;
        const isChecked = event.target.innerHTML === unselectText;
        const newInnerHTML = isChecked ? selectText : unselectText;
        for (const target of this.ontologyTargets) {
            target.querySelector('input').checked = !isChecked;
        }
        event.target.innerHTML = newInnerHTML;
    }
    apply() {
        const select = document.getElementById(`select_${this.idValue}`);
        const tsControl = document.getElementById(`select_${this.idValue}-ts-control`);
        const values = this.#selectedOntologies(this.ontologyTargets);
        for (const value of values) {
            tsControl.value = value;
            tsControl.dispatchEvent(new Event('input', { bubbles: true }));
            select.parentNode.querySelector(`div[data-value="${value}"]`).click();
        }
        this.exitTarget.click();
    }
    clear() {
        const selectedItems = document.getElementById(`select_${this.idValue}`).parentNode.querySelectorAll('a');
        selectedItems.forEach(item => {
            item.click();
        });
    }
    
    #selectedOntologies(ontologies) {
        return ontologies
            .filter(ontology => ontology.querySelector('input').checked)
            .map(ontology => ontology.querySelector('input').name);
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