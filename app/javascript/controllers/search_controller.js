import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = [ "advancedOptions", "hideOptionsButton", "showOptionsButton" ]
  connect() {
    console.log(this.element)
    
  }
  show_advanced_options(){
    this.advancedOptionsTarget.classList.remove('d-none')
    this.hideOptionsButtonTarget.classList.remove('d-none')
    this.showOptionsButtonTarget.classList.add('d-none')
  }
  hide_advanced_options(){
    this.advancedOptionsTarget.classList.add('d-none')
    this.hideOptionsButtonTarget.classList.add('d-none')
    this.showOptionsButtonTarget.classList.remove('d-none')
  }
}
