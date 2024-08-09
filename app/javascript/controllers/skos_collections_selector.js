import {Controller} from "@hotwired/stimulus"
import {useTomSelect} from "../mixins/useTomSelect";

// Connects to data-controller="skos-collection-selector"
export default class extends Controller {
    // TODO to update to use TomSelect
    static values = {
        name: String,
        enableColors: {type: Boolean, default: false}
    }

    connect() {
        this.select = useTomSelect(this.element, {
                width: '100%',
                plugins: ['remove_button'],
                render: {
                    item:  (data, escape)  => {
                        if(this.enableColorsValue){
                            const bgColor = data.color || '#ccc';
                            return '<div style="background-color:' + escape(bgColor) + '; color: white">' + escape(data.text) + '</div>';
                        }else {
                            return '<div>' + escape(data.text) + '</div>'
                        }

                    }
                }
            },
            this.#onChange.bind(this))
    }

    #onChange(event) {
        const selected = this.#getSelectedOptions()
        const key = this.hasNameValue ? this.nameValue : event.currentTarget.name
        const newData = {
            [key]: selected.map(x => x.value)
        }
        this.element.dispatchEvent(new CustomEvent('changed', {
            detail: {
                data: newData
            },
            bubbles: true,
            cancelable: true,
        }))
    }

    #getSelectedOptions() {
        return this.select.items.map(item => this.select.options[item])
    }
}
