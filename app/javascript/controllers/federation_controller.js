import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="federation"
export default class extends Controller {
    static values = {
        config: Object,
      }
    connect() {
        const style = document.createElement('style');
        let styles = '';
        Object.entries(this.configValue).forEach(([key, portal]) => {
            styles += `.federated-icon-${key} path { fill: ${portal.color} !important; }\n`;
        });
        style.innerHTML = styles;
        document.head.appendChild(style);
    }
  }
  