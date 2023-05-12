import {Controller} from "@hotwired/stimulus";

// Connects to data-controller="toggle-input"
export default class extends Controller {
  static targets = ['option']


  selectFirstOption(){
    this.element.classList.remove('off')
    this.#firstOption().checked = true
    this.#secondOption().checked = false

  }
  selectSecondOption(){
    this.element.classList.add('off')
    this.#secondOption().checked = true
    this.#firstOption().checked = false
  }

  #secondOption(){
    return this.optionTargets[1]
  }
  #firstOption(){
    return this.optionTargets[0]
  }
}
