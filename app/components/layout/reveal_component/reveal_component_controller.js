import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    hiddenClass: { type: String, default: 'd-none' }
  }

  static targets = ['hideButton', 'showButton', 'item']

  /*
      Toggle all the items
   */
  toggle (event) {
    this.#getItems(event).forEach((s) => {
      s.classList.toggle(this.hiddenClassValue)
    })
  }

  /*
      Hide all the items except the selected one
   */
  select (event) {
    let selectedValue = event.target.value
    let items = this.#getItems(event)
    items.forEach((s) => {
      s.classList.add(this.hiddenClassValue)
    })

    items.forEach((s) => {
      if (selectedValue === s.dataset.value) {
        s.classList.remove(this.hiddenClassValue)
      }
    })
  }

  show (event) {
    this.#getItems(event).forEach((s) => s.classList.remove(this.hiddenClassValue))
    this.hideButtonTarget.classList.remove(this.hiddenClassValue)
    this.showButtonTarget.classList.add(this.hiddenClassValue)
  }

  hide (event) {
    this.#getItems(event).forEach((s) => s.classList.add(this.hiddenClassValue))
    this.hideButtonTarget.classList.add(this.hiddenClassValue)
    this.showButtonTarget.classList.remove(this.hiddenClassValue)
  }

  #ItemById (event) {
    let button = event.target.closest('[data-id]')
    return document.getElementById(button.dataset.id)
  }

  #getItems (event) {
    let items
    if (this.hasItemTarget) {
      items = this.itemTargets
    } else {
      items = [this.#ItemById(event)]
    }
    return items
  }

}