import {Controller} from "@hotwired/stimulus"
export default class extends Controller {
    static targets = ['input', 'context']
    connect(){
      this.#display_annotations_contexts()
    }
    #display_annotations_contexts(){
      let annotation_contexts = this.contextTargets;
        let textarea = this.inputTarget
        for (var i = 0; i < annotation_contexts.length; i++) {
          var context = annotation_contexts[i];
          let from = context.dataset.from - 1
          let to = context.dataset.to
          let textBefore = textarea.value.substring(0, from);
          if(textBefore.length>0){
            textBefore = '... ' + this.#last_two_words(textBefore)
          }
          let highlightedText = textarea.value.substring(from, to);
          let textAfter = textarea.value.substring(to);
          if(textAfter.length>1){
            textAfter = this.#first_three_words(textAfter) + ' ...'
          }
          context.innerHTML = textBefore + '<span class="highlighted-annotation"> ' + highlightedText + ' </span>' + textAfter;
        }
    }
    #last_two_words(text){
      return text.trim().replace(/[\r\n]+/g, ' ').split(' ').slice(-2).join(' ');
    }
    #first_three_words(text){
      return text.trim().replace(/[\r\n]+/g, ' ').split(' ').slice(0, 3).join(' ')
    }
}