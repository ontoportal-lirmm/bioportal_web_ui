import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = [ "subOntologies" ]
  connect(){
    //console.log('component_is_working')
  }

  showSubOntologies(){
    if(this.subOntologiesTarget.classList.contains('d-none')){
        this.subOntologiesTarget.classList.remove("d-none")
    } else {
        this.subOntologiesTarget.classList.add("d-none")
    }
  }
}
