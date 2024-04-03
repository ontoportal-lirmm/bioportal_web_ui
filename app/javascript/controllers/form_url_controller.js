import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
 
    submit(event){
        event.preventDefault();
        let selectedOptions, hiddenInput, optionString, selectElem
        let  allSelects = this.element.querySelectorAll('select[name$="[]"]');
        for (const select of allSelects) {
            const selectElem = select.name.substring(0, select.name.indexOf('['));
            const selectedOptions = select.selectedOptions;
            if (selectedOptions.length > 0) {
                const optionString = Array.from(selectedOptions, option => option.value).join(",");
                const hiddenInput = this.#create_hidden_input_element(optionString, selectElem);
                event.currentTarget.appendChild(hiddenInput);
                select.remove();
            }
        }
        
        event.currentTarget.submit();
    }

    #create_hidden_input_element(optionString, name){
        let hiddenInput = document.createElement('input');
        hiddenInput.type = 'hidden';
        hiddenInput.name = name;
        hiddenInput.value = optionString;
        return hiddenInput
    }
}
