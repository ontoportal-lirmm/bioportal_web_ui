import {Controller} from "@hotwired/stimulus"
import {UseModal} from "../mixins/useModal";

// Connects to data-controller="show-modal"
export default class extends Controller {
    static values = {
        targetModal: {type: String, default: '#application_modal'},
        title: String,
        size: String,
    }


    connect() {
        this.modal = new UseModal()
        this.boundHide = this.hide.bind(this)
        this.modal.onClose(this.element,  this.boundHide)
    }

    disconnect() {
        this.modal.onCloseRemoveEvent(this.element, this.boundHide)
    }

    show() {
        this.setTitle()
        this.setSize()
        let target = this.targetModalElement
        if (target) {
            this.modal.showModal(target)
        }
    }

    hide() {
        let target = this.targetModalElement
        if (target) {
            this.modal.hideModal(target)
        }

    }

    get targetModalElement() {
        return document.querySelector(this.targetModalValue)
    }

    get modalTitle() {
        return document.querySelector(`${this.targetModalValue} .modal-title`)
    }

    setTitle() {
        let titleElem = this.modalTitle
        if(titleElem){
            titleElem.innerHTML = this.titleValue
        }
    }

    setSize() {
        const target = this.targetModalElement
        const newSize = this.sizeValue
        if (target && newSize){
            const modalContainer = target.firstElementChild
            const classes = modalContainer.classList
            const oldSize = classes.item(classes.length - 1)
            modalContainer.classList.remove(oldSize)
            modalContainer.classList.add(newSize)
        }
    }
}
