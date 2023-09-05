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
            create: true,
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
            const options = this.selectedValuesTarget.options
            for (const element of options) {
                element.selected = selectedOptions.indexOf(element.value) >= 0;
            }
            jQuery(this.selectedValuesTarget).trigger("chosen:updated")
        }

        if (this.openAddValue) {
            myOptions['create'] = true;
        }
    }

    #toggle() {
        if (this.selectedValuesTarget.value === 'other') {
            this.#displayOtherValueField()
        } else {
            this.#hideOtherValueField()
        }
    }

    #triggerChange() {
        document.dispatchEvent(new Event('change', {target: this.element}))
    }

    #hideOtherValueField() {
        this.inputValueFieldTarget.value = ""
        this.btnValueFieldTarget.style.display = 'none'
        this.inputValueFieldTarget.style.display = 'none'
    }


}