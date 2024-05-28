import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="topnav-responsiveness"
export default class extends Controller {
  static targets = ['navMenu']

  connect() {
    let checkbox = this.navMenuTarget
    let divs = document.querySelectorAll('.top-nav, .top-nav-ul, .nav-items, .nav-ul-li, .nav-input, .nav-a, .nav-language, .supportMenuDropdownLink');
    checkbox.addEventListener('change', function() {
      if (this.checked) {
        divs.forEach(function(div) {
          div.classList.add('show-responsive');
        });
      } else {
        divs.forEach(function(div) {
          div.classList.remove('show-responsive');
        });
      }
    });
  }
}
