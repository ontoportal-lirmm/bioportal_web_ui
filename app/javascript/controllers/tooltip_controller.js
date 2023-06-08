import { Controller } from "@hotwired/stimulus"
import useTooltip from "../mixins/useTooltip";

// Connects to data-controller="tooltip"
export default class extends Controller {

  static values = {
    position: String
  }

  connect() {
    useTooltip(this.element, this.positionValue)
  }

}
