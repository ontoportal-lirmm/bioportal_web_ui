import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        color: String,
        portalName: String,
      }
    connect() {
      this.#initIconsStyle()
    }

    #initIconsStyle(){
      const style = document.createElement('style');
      style.innerHTML = `.federated-icon-${this.portalNameValue} path { fill: ${this.colorValue} !important; }\n`;
      document.head.appendChild(style);
    }

  }
