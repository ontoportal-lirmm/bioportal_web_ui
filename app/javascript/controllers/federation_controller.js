import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="federation"
export default class extends Controller {
    static values = {
        config: Object,
      }
    static targets = ['chips']
    connect() {
      this.#initIconsStyle()
      this.#initInputChips()
    }
    #initIconsStyle(){
      const style = document.createElement('style');
      let styles = '';
      Object.entries(this.configValue).forEach(([key, portal]) => {
          styles += `.federated-icon-${key} path { fill: ${portal.color} !important; }\n`;
      });
      style.innerHTML = styles;
      document.head.appendChild(style);
    }

    #initInputChips(){
      for (const key in this.configValue) {
        $.ajax({
          url: this.configValue[key].api,
          type: 'GET',
          success: function(response) {
              console.log('working');
          },
          error: function() {
              let chipsInputs = this.chipsTarget.querySelectorAll('input') 
              Array.from(chipsInputs).forEach(input => {
                if (input.value === this.configValue[key].name.toLowerCase()) {
                    input.disabled = true; 
                    input.parentNode.style.opacity = '0.5';
                    input.parentNode.setAttribute('data-controller', 'tooltip');
                    input.parentNode.setAttribute('title', `${this.configValue[key].name} is currently down`);
                }
              });
          }.bind(this)
        });
      }
    }
  }
  