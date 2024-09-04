import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="limited-container"

export default class extends Controller {
    static targets = [ "content", "revealbutton"]
    static values = {
        height: Number
    }
    connect(){
        this.contentTarget
        if(this.contentTarget.offsetHeight<this.heightValue && this.contentTarget.offsetHeight!=0){
            this.revealbuttonTarget.classList.add('d-none') 
        }
    }
    toggle(){
        if (this.contentTarget.style.maxHeight === 'unset'){
            this.contentTarget.style.maxHeight = `${this.heightValue}px`
        }else{
            this.contentTarget.style.maxHeight = 'unset'
        }
        
    }

}