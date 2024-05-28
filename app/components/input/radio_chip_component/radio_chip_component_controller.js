import {Controller} from "@hotwired/stimulus";


export default class extends Controller {
    connect(){
        if(this.element.children[0].checked){
            this.element.classList.add('selected')
        }
    }
    check(){
        if(this.element.children[0].checked){
            this.element.classList.add('selected')
        }
        let other_radios = document.getElementsByClassName(this.element.children[0].name)
        let element = this.element
        Array.from(other_radios).forEach(function(otherRadio){
            if (otherRadio !== element) {
              otherRadio.classList.remove('selected')
            }
        });
    }
}