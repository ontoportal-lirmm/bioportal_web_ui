import { Controller } from '@hotwired/stimulus'

export default class extends Controller {

  static targets = ['content', 'copy', 'check']
  static values = {
    hiddenCss: { type: String, default: 'd-none' },
    successDuration: { type: Number, default: 2000 }
  }
  
  copy () {
    const text = this.contentTarget.innerHTML || this.contentTarget.value
    navigator.clipboard.writeText(text).then(() => {
      this.#copied()
    })
  }
  
  copy_concept_content () {
    const activeTab = document.querySelector('.concepts-content-format .tab-content .tab-pane.active');
    if(activeTab.id != 'html_content'){
      let resource_content = activeTab.querySelector('.content-finder-result').getAttribute('data-content-finder-result-value')
      navigator.clipboard.writeText(resource_content).then(() => {
          this.#copied();
      })
    }else{
      navigator.clipboard.writeText("").then(() => {
        this.#copied()
      })
    }
    
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
