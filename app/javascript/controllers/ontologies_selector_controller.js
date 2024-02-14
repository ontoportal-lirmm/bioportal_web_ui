import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['submit']
    input(){
        this.submitTarget.click()
    }
    change(){
        this.submitTarget.click()
    }
}