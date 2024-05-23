import { Controller } from '@hotwired/stimulus'

export default class extends Controller {

  static targets = ['content', 'copy', 'check']
  static values = {
    hiddenCss: { type: String, default: 'd-none' },
    successDuration: { type: Number, default: 2000 }
  }
  
  copy () {
    const text = this.contentTarget.innerHTML || this.contentTarget.value
    navigator.clipboard.writeText(text.trim()).then(() => {
      this.#copied()
    })
  }
  
  #copied () {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.#toggleCopy()

    this.timeout = setTimeout(() => {
      this.#toggleCopy()
    }, this.successDurationValue)
  }

  #toggleCopy () {
    this.copyTarget.classList.toggle(this.hiddenCssValue)
    this.checkTarget.classList.toggle(this.hiddenCssValue)
  }
}
