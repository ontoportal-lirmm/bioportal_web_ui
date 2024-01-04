import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal-by-id"
export default class extends Controller {
  reveal(event){
    let button = event.target.closest("[data-id]");
    let block = document.getElementById(button.dataset.id)
    block.classList.toggle("d-none");
  }
}
