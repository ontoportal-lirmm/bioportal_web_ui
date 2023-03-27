import { Controller } from "@hotwired/stimulus"
import { showLoader } from "../mixins/showLoader";

export default class extends Controller {
  
  
  static targets = ["sections"]


  onClick(event) {
    
    const anchorElement = event.target.closest('a');

    // add active class to the clicked tab
    
    if (anchorElement) {

      showLoader(this.sectionsTarget);

      anchorElement.classList.add('active');
     
      // remove active class from the other tabs
      const otherTabs = anchorElement.parentElement.parentElement.querySelectorAll('a');
      otherTabs.forEach(tab => {
        if (tab !== anchorElement) {
          tab.classList.remove('active');
        }
      });

      const href = anchorElement.getAttribute('href');
      Turbo.visit(href);
    }

  }
}
