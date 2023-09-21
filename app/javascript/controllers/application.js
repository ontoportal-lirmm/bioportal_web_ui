import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application


import Flatpickr from "stimulus-flatpickr"

application.register("flatpickr", Flatpickr);
import NestedForm from 'stimulus-rails-nested-form'
application.register('nested-form', NestedForm)
import ReadMore from 'stimulus-read-more'
application.register('read-more', ReadMore)
import Timeago from 'stimulus-timeago'
application.register('timeago', Timeago)
export { application }
import Reveal from 'stimulus-reveal-controller'
application.register('reveal', Reveal)

