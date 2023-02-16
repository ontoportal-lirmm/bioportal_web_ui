import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application


import Flatpickr from "stimulus-flatpickr"

application.register("flatpickr", Flatpickr);
import NestedForm from 'stimulus-rails-nested-form'
application.register('nested-form', NestedForm)

export { application }


