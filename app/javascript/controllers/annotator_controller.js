import {Controller} from "@hotwired/stimulus"
export default class extends Controller {
    connect(){
        let annotation_contexts = document.getElementsByClassName('annotation-context');
        let textarea = document.getElementById('annotator-text-area')
        for (var i = 0; i < annotation_contexts.length; i++) {
          var context = annotation_contexts[i];
          let from = context.dataset.from - 1
          let to = context.dataset.to
          let textBefore = textarea.value.substring(0, from);
          if(textBefore.length>0){
            textBefore = '...' + textBefore.trim().replace(/[\r\n]+/g, ' ').split(' ').slice(-2).join(' ');
          }
          let highlightedText = textarea.value.substring(from, to);
          let textAfter = textarea.value.substring(to);
          if(textAfter.length>1){
            textAfter = textAfter.trim().replace(/[\r\n]+/g, ' ').split(' ').slice(0, 3).join(' ') + '...'
          }
          context.innerHTML = textBefore + '<span class="highlighted-annotation"> ' + highlightedText + ' </span>' + textAfter;
        }
    }
}