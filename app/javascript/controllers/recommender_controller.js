import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recommender"
export default class extends Controller {
  static targets = ['button', 'input', 'result', 'maxset', 'empty', 'ontologieschoice']

  connect(){
    if(document.querySelector('input[name="highlighted_recommendation"]:checked') !== null){
      this.handleHighlightedChange()
    }  

    let ontologies_choice = this.ontologieschoiceTarget.childNodes[1].childNodes[1]
    if(!ontologies_choice.checked){
      this.togglesets()
    }
  }
  edit(event){
    this.#toggle(this.buttonTarget)
    this.#toggle(event.currentTarget)
    this.#toggle(this.inputTarget)
    this.#toggle(this.resultTarget)
  }
  togglesets(){
    this.#toggle(this.maxsetTarget)
    this.#toggle(this.emptyTarget)
  }

  handleHighlightedChange(){
    let recommandations_area = this.resultTarget
    let jsonString = document.querySelector('input[name="highlighted_recommendation"]:checked').value;
    let jsonStringModified = jsonString.replace(/:text/g, '"text"').replace(/:link/g, '"link"').replace(/=>/g, ':');
    let jsonArray = JSON.parse(jsonStringModified);
    var words = recommandations_area.textContent.split(/\s+/);
    for (var i = 0; i < words.length; i++) {
        var word = words[i].replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, '').toLowerCase(); // Remove punctuation and convert to lowercase
        var foundItem = jsonArray.find(item => item.text.toLowerCase() === word);

        if (foundItem) {
          // Replace the word with <a> tag
          words[i] = '<a href="' + foundItem.link + '">' + words[i] + '</a>';
        }
      }
    recommandations_area.innerHTML = words.join(' ');
  }

  #toggle(element){
    element.classList.toggle('d-none')
  }
}
