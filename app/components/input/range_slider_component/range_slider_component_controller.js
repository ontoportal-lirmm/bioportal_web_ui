import {Controller} from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ['selector', 'range', 'selection', 'input']
    connect(){
        this.#updateSelector()
    }

    handleInput(){
        this.#updateSelector()
    }

    #updateSelector(){
        let pourcentage = (this.inputTarget.value / this.inputTarget.max) * 100
        this.selectorTarget.style.left = (pourcentage*0.95)+"%"
        this.rangeTarget.style.width = (pourcentage*0+pourcentage)+"%"
        this.selectionTarget.innerHTML = this.inputTarget.value
    }
}
