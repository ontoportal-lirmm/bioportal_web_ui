import {Controller} from "@hotwired/stimulus"
import {useChosen} from "../mixins/useChosen";

// Connects to data-controller="chosen"
export default class extends Controller {
    static values = {
        name: String,
        enableColors: {type: Boolean, default: false}
    }

    connect() {
        useChosen(this.element, {width: '100%', allow_single_deselect: true}, this.#onChange.bind(this))
    }

    #onChange(event) {
        const selected = Array.from(event.currentTarget.selectedOptions)

        if(this.enableColorsValue){
            this.#setColors(selected)
        }

        const key = this.hasNameValue ? this.nameValue : event.currentTarget.name
        const newData = {
            [key]: selected.map(x => x.value)
        }
        this.element.dispatchEvent(new CustomEvent('changed', {
            detail: {
                data: newData
            }
        }))
    }

    #setColors(selected){
        const snakeCase = string => {
            return string.replace(/\W+/g, " ")
                .split(/ |\B(?=[A-Z])/)
                .map(word => word.toLowerCase())
                .join('_');
        }
        const allChosenSelected = Array.from(document.querySelectorAll(`#${snakeCase(this.element.id +'_chosen')} .search-choice`))
        selected.forEach((s) => {
            let color = s.dataset.color
            if (color) {
                const chosenSelected = allChosenSelected.filter(x => x.firstElementChild.textContent === s.text).pop()
                const chosenText = chosenSelected.firstElementChild
                const chosenClose = chosenSelected.lastElementChild

                chosenSelected.style.display =  "flex"
                chosenSelected.style.padding =  "1px"
                chosenSelected.style.paddingTop =  "2px"
                chosenSelected.style.paddingBottom =  "2px"


                chosenText.style.backgroundColor =  color
                chosenText.style.display = "inline-block"
                chosenText.style.padding = "5px"
                chosenText.style.borderRadius = "5px"
                chosenText.style.color = "#fff"
                chosenText.style.marginLeft =  "2px"
                chosenText.style.marginRight = "2px"

                chosenClose.style.position = "unset"
                chosenClose.style.margin = "auto"



            }
        })
    }
}
