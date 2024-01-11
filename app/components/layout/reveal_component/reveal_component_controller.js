import { Controller } from "@hotwired/stimulus"

export default class extends Controller{
    static values = {
        condition: String,
        hiddenClass : {type: String, default: "d-none"}
    }

    static targets = ["hideButton", "showButton", 'item' ]

    connect(){
        let element
        if (
            this.element.childNodes[0] &&
            this.element.childNodes[0].childNodes[0] &&
            this.element.childNodes[0].childNodes[0].childNodes[3]
          ){
            element = this.element.childNodes[0].childNodes[0].childNodes[3]
            if(element.tagName == "SELECT"){
                document.getElementById(element.value).classList.remove(this.hiddenClassValue)
            }
        }
    }
    toggle(event) {
        if (!this.conditionValue) {
            this.#toggle(event)
        } else if (this.#shown() && !this.#conditionChecked(event)) {
            this.#toggle(event)
        } else if (!this.#shown() && this.#conditionChecked(event)) {
            this.#toggle(event)
        }
    }

    select(event){
        console.log('woqsfqsdfqsdfrking')
        let myItems = document.getElementsByClassName(event.target.parentNode.parentNode.getAttribute('data-items'))
        for(var i = 0; i < myItems.length; i++) {
            myItems[i].classList.add('d-none');
        }
        document.getElementById(event.target.value).classList.remove(this.hiddenClassValue)
    }

    show(event){
        this.#getItems(event).classList.remove(this.hiddenClassValue)
        this.hideButtonTarget.classList.remove(this.hiddenClassValue)
        this.showButtonTarget.classList.add(this.hiddenClassValue)
    }
    hide(event){
        this.#getItems(event).classList.add(this.hiddenClassValue)
        this.hideButtonTarget.classList.add(this.hiddenClassValue)
        this.showButtonTarget.classList.remove(this.hiddenClassValue)
    }
    

    #conditionChecked(event) {
        return this.conditionValue === event.target.value
    }

    #shown() {
        return !this.itemTargets[0].classList.contains(this.class);
    }

    #toggle(event) {        
        this.#getItems(event).forEach((s) => {
          s.classList.toggle(this.hiddenClassValue);
        });
    }

    #ItemById(event){
        let button = event.target.closest("[data-id]");
        return document.getElementById(button.dataset.id);
    }
    #getItems(event){
        let items
        if(this.hasItemTarget){
            items = this.itemTarget
        } else {
            items = [this.#ItemById(event)]
        }
        return items
    }

}