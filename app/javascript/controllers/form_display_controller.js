import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-options-display"
export default class extends Controller {

  static targets = ['option1', 'option2']
  static values = {
    hiddenClass: String
  }

  connect() {
    this.class = this.hasHiddenClassValue ? this.hiddenClassValue : "hidden"
  }

  showOption1(){
    this.#hide(this.option2Targets)
    this.#show(this.option1Targets)
  }

  showOption2(){
    this.#hide(this.option1Targets)
    this.#show(this.option2Targets)
  }


  #show(optionElems){
    optionElems.forEach(x => x.classList.remove(this.class))

  }

  #hide(optionElems){
    optionElems.forEach(x => x.classList.add(this.class))
  }


}
