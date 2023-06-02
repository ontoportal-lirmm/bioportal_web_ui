import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="home-search"
export default class extends Controller {
  static targets = [ "input", "dropDown", "ontology", "searchedOntologies", "searchOntologyContent", "homeSearchOntologies" ]
  static values = {
    ontologies: Array
  }
  connect() {
    this.ontologies = this.ontologiesValue
    this.input = this.inputTarget
    this.dropDown = this.dropDownTarget
    this.ontology = this.ontologyTarget
    this.searchedOntologies = this.searchedOntologiesTarget
    this.searchOntologyContent = this.searchOntologyContentTarget
    this.homeSearchOntologies = this.homeSearchOntologiesTarget
  }

  search(){
      this.#searchInput()
  }

  prevent(event){
    event.preventDefault();
  }
  blur(){
    this.dropDown.style.display = "none";
    this.input.classList.remove("home-dropdown-active");
  }

  
  #scrollDown(currentScroll) {
    const startPosition = window.pageYOffset;
    const distance = 300 - currentScroll;
    const duration = 1000;
    let start = null;

    function scrollAnimation(timestamp) {
      if (!start) start = timestamp;
      const progress = timestamp - start;
      const scrollPosition = startPosition + easeInOutCubic(progress, 0, distance, duration);
      window.scrollTo(0, scrollPosition);
      if (progress < duration) {
        window.requestAnimationFrame(scrollAnimation);
      }
    }

    function easeInOutCubic(t, b, c, d) {
      t /= d / 2;
      if (t < 1) return c / 2 * t * t * t + b;
      t -= 2;
      return c / 2 * (t * t * t + 2) + b;
    }

    window.requestAnimationFrame(scrollAnimation);
  }

  #searchInput() {
    let results_list = []
    const class_search_path = "/search?query="
    const browse_search_path = "/ontologies?search="
    const inputValue = this.input.value.trim();
    if (inputValue.length > 0) {
        this.ontology.innerHTML = inputValue;
        this.searchedOntologies.innerHTML = inputValue;
        this.searchOntologyContent.href = class_search_path+inputValue;
        this.homeSearchOntologies.href = browse_search_path+inputValue;
        this.dropDown.innerHTML = ""
        let breaker = 0
        for (var i = 0; i < this.ontologies.length; i++) {
          if (breaker == 4){
            break;
          }
          // Get the current item from the ontologies array
          var item = this.ontologies[i];

          // Check if the item contains the substring
          if (item[0].toLowerCase().includes(inputValue.toLowerCase()) || item[1].toLowerCase().includes(inputValue.toLowerCase())) {
            results_list.push(item);
            breaker = breaker + 1
          }
        }
        
        results_list.forEach((item)=> {
            let link = document.createElement("a");
            link.href = "/ontologies/"+item[1];
            link.className = "home-search-ontology-content";

            let p1 = document.createElement("p");
            p1.id = "seached-ontology";
            p1.className = "home-searched-ontology";
            p1.textContent = item[0]+" "+"("+item[1]+")";

            let p2 = document.createElement("p");
            p2.className = "home-result-type";
            p2.textContent = "Ontology";

            link.appendChild(p1);
            link.appendChild(p2);
            
            this.dropDown.appendChild(link);  

        });
        this.dropDown.appendChild(this.homeSearchOntologies);
        this.dropDown.appendChild(this.searchOntologyContent);
        this.dropDown.style.display = "block";
        this.input.classList.add("home-dropdown-active");

        if (window.scrollY < 300) {
          this.#scrollDown(window.scrollY);
        }
        
        
    } else {
        this.dropDown.style.display = "none";
        this.input.classList.remove("home-dropdown-active");
    }
  }
}
