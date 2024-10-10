import ShowModalController from "../../javascript/controllers/show_modal_controller";

// Connects to data-controller="turbo-modal"
export default class extends ShowModalController {

    static targets = ["content"]
    static values = {
        show: Boolean
    }

    connect() {
        super.connect();
        if (this.showValue) {
            this.show()
        }
    }

    show() {
        this.modal.showModal(this.element)
    }

    hide() {
        this.modal.hideModal(this.element)
        if (this.contentTarget) {
            this.contentTarget.removeAttribute("src")
            this.contentTarget.replaceChildren()
        }
    }


}