import {Controller} from "@hotwired/stimulus"
import {useTomSelect} from "../../javascript/mixins/useTomSelect"

export default class extends Controller {
    static values = {
        multiple: {type: Boolean, default: false},
        openAdd: {type: Boolean, default: false},
        required: {type: Boolean, default: false}
    };


    connect() {
        let myOptions = {}

        myOptions = {
            render: {
                option: (data) => {
                    return `<div> ${data.text} </div>`
                },
                item: (data) => {
                    return `<div> ${data.text} </div>`
                }
            }
        }

        if (this.multipleValue) {
            myOptions['onItemAdd'] = function(){
                this.setTextboxValue('');
                this.refreshOptions();
            }
            myOptions['plugins'] = ['remove_button'];
        }

        if (this.openAddValue) {
            myOptions['create'] = true;
        }

        this.select = useTomSelect(this.element, myOptions, this.#triggerChange.bind(this))
    }

    #triggerChange() {
        if (this.requiredValue && !this.multipleValue && this.select.getValue() === ""){
            this.select.setValue(Object.keys(this.select.options)[0])
        }

        document.dispatchEvent(new Event('change', { target: this.element }))
    }
}