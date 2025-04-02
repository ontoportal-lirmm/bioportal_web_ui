import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['ontology', 'table', 'exit', 'form', 'frame']
    static values = {
        id: String,
        selectAll: String,
        unselectAll: String
    }

    input(event) {
        this.change(event)
    }

    change(event) {
        const formData = new FormData(this.formTarget);
        const url = this.frameTarget.getAttribute('src').split('?')[0];
        this.frameTarget.src = url + '?' + new URLSearchParams(formData).toString();
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
            tsControl.dispatchEvent(new Event('input', {bubbles: true}));
            let selectorVal = select.parentNode.querySelector(`div[data-value="${value}"]`)
            if (selectorVal) {
                selectorVal.click();
            } else {
                select.tomselect.addOption({value: value.value, text: value.name});
                select.tomselect.addItem(value.value)
                selectorVal = select.parentNode.querySelector(`div[data-value="${value.value}"]`)
                selectorVal.click();
            }
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
            .map(ontology => {
                const input = ontology.querySelector('input');
                return {name: input.name, value: input.value};
            });
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