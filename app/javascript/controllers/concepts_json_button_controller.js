import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['button']

    update(){
        setTimeout(() => {
            const tabsList = this.element.querySelectorAll('.nav-item');
            const jsonLink = Array.from(tabsList).find(tab => tab.classList.contains('active'))?.querySelector('a').getAttribute('data-json-link');
            const conceptsJsonLink = this.buttonTarget.querySelector('a');
            if (jsonLink) {
                conceptsJsonLink.href = jsonLink;
                conceptsJsonLink.style.display = 'flex'
            } else {
                conceptsJsonLink.style.display = 'none'
            }
        }, 1);
    }
}