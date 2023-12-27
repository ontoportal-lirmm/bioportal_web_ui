import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "subOntologies" , "reuses" ]
  showSubOntologies(){
    this.subOntologiesTarget.classList.toggle("d-none")
  }
  showReuses(){
    this.reusesTarget.classList.toggle("d-none")
  }
}
