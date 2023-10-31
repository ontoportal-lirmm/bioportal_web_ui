import Reveal from 'stimulus-reveal-controller'

export default class extends Reveal {
    static values = {
        condition: String
    }

    connect() {
        super.connect()
    }

    toggle(event) {
        if (!this.conditionValue) {
            super.toggle()
        } else if (this.#shown() && !this.#conditionChecked(event)) {
            super.toggle()
        } else if (!this.#shown() && this.#conditionChecked(event)) {
            super.toggle()
        }
    }

    #conditionChecked(event) {
        return this.conditionValue === event.target.value
    }

    #shown() {
        return !this.itemTargets[0].classList.contains(this.class);
    }

}