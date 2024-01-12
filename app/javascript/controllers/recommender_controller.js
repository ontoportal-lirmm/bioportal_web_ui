import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recommender"
export default class extends Controller {
  static targets = ['button', 'input', 'result']
  edit(event){
    console.log('working a chikh')
    this.#toggle(this.buttonTarget)
    this.#toggle(event.currentTarget)
    this.#toggle(this.inputTarget)
    this.#toggle(this.resultTarget)
    
  }

  #toggle(element){
    element.classList.toggle('d-none')
  }

}
