import {Controller} from "@hotwired/stimulus"
import {useTomSelect} from "../../javascript/mixins/useTomSelect"

export default class extends Controller {
    static values = {
        multiple: {type: Boolean, default: false},
        openAdd: {type: Boolean, default: false}
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

        useTomSelect(this.element, myOptions, this.#triggerChange.bind(this))
    }

    #triggerChange() {
        document.dispatchEvent(new Event('change', {target: this.element}))
    }
}