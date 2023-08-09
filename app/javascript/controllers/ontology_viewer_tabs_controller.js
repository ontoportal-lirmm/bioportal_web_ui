import { Controller } from "@hotwired/stimulus"
import {HistoryService} from "../mixins/useHistory";


export default class extends Controller {
  
  
  static targets = ["languageSelector"]
  static values = {
    languageSections: Array
  }

  connect() {
    this.changeEvent = this.languageSelectorTarget.addEventListener("change",  (e) => {
      this.languageSectionsValue.forEach(p => {
        let elem = document.getElementById("language_selector_hidden_"+p)
        if(elem){
          elem.value = e.target.value
          elem.dispatchEvent(new Event('change'))
        }
      })
    })
  }

  destroy(){
    this.changeEvent.removeEventListener()
  }

  updateLanguageSelector(event) {
    console.log('language selector update')
    let page = event.detail.data.selectedTab
    this.#disableLanguageSelector(page)
  }

  #disableLanguageSelector(selectedSection){
    if (this.languageSectionsValue.includes(selectedSection)){
      this.languageSelectorTarget.removeAttribute("disabled")
      this.languageSelectorTarget.style.visibility = 'visible'
    } else{
      this.languageSelectorTarget.setAttribute("disabled", true)
      this.languageSelectorTarget.style.visibility = 'hidden'
    }
  }


}
