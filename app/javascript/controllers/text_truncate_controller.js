import ReadMore from "stimulus-read-more";

// Connects to data-controller="text-truncate"
export default class extends ReadMore {
    static targets = ['button']

    connect() {
        super.connect()
        if (!this.#isTextClamped()) {
            this.#hideButton()
        }
    }

    #isTextClamped() {
        return this.contentTarget.scrollHeight > this.contentTarget.clientHeight
    }

    #hideButton() {
        this.buttonTarget.style.display = 'none'
    }
}
