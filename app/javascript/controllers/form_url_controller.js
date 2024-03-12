import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
    static targets = ['form']
    static values = {
        options: Array
    }
    
    submit(event){
        event.preventDefault();
        let selectedOptions, hiddenInput, optionString
        for(let i=0; i<this.optionsValue.length; i++){
            selectedOptions = event.currentTarget.querySelector(`select[name="${this.optionsValue[i]}[]"]`).selectedOptions;
            if(selectedOptions.length>0){
                optionString = this.#array_to_string(selectedOptions)
                hiddenInput = this.#create_hidden_input_element(optionString, this.optionsValue[i])
                event.currentTarget.appendChild(hiddenInput);
                this.#remove_html_element(event.currentTarget.querySelector(`select[name="${this.optionsValue[i]}[]"]`))
            }
        }
        event.currentTarget.submit();
    }
    #array_to_string(selectedOptions){
        let optionString = "";
        for (const option of selectedOptions) {
            optionString += option.value + ",";
        }
        return optionString.slice(0, -1);
    }
    #create_hidden_input_element(optionString, name){
        let hiddenInput = document.createElement('input');
        hiddenInput.type = 'hidden';
        hiddenInput.name = name;
        hiddenInput.value = optionString;
        return hiddenInput
    }
    #remove_html_element(element){
        return element.remove();
    }
}
