import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="language-change"
// This controller is used to change the language of the Concepts, Schemes and Collections
export default class extends Controller {

  dispatchLangChangeEvent() {
    debugger
    this.element.dispatchEvent(new CustomEvent('lang_changed', {
      bubbles: true,
      cancelable: true,
      detail: {
        data: {
          language: [this.element.value]
        }
      }
    }));
  }

}
