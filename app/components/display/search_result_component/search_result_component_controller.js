import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "subOntologies" , "reuses" ]
  showSubOntologies(){
    if(this.subOntologiesTarget.classList.contains('d-none')){
        this.subOntologiesTarget.classList.remove("d-none")
    } else {
        this.subOntologiesTarget.classList.add("d-none")
    }
  }
  showReuses(){
    if(this.reusesTarget.classList.contains('d-none')){
      this.reusesTarget.classList.remove("d-none")
    } else {
        this.reusesTarget.classList.add("d-none")
    }
  }
}
