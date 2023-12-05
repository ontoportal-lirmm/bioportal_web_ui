import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="show-filter-count"

export default class extends Controller {
    static targets = ["countSpan"]

    updateCount() {
        const checkInputs = this.element.querySelectorAll('input:checked')
        this.element.querySelectorAll('turbo-frame').forEach(x => {
            x.setAttribute('busy', 'true')
        })
        const count = checkInputs.length
        this.countSpanTarget.style.display = count === 0 ? "none" : "inline-block"
        this.countSpanTarget.innerHTML = count === 0 ? "" : count
    }
}
