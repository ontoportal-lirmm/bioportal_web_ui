import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        classUrl: String,
        apiKey: String
      }
    static targets = ['button']

    update(event){
        const baseClassUrl = this.classUrlValue;
        const apikey = `apikey=${this.apiKeyValue}`;
        const tabsList = event.currentTarget.querySelectorAll('.nav-item');
        const links = {
            details_tab: `${baseClassUrl}?${apikey}&display=all`,
            instances_tab: `${baseClassUrl}/instances?${apikey}`,
            notes_tab: `${baseClassUrl}/notes?${apikey}`,
            mappings_tab: `${baseClassUrl}/mappings?${apikey}`,
        };

        const selectedItemId = Array.from(tabsList).find(tab => tab.classList.contains('active'))?.querySelector('a').id; 

        const jsonLink = links[selectedItemId];
        const conceptsJsonLink = this.buttonTarget.querySelector('a');
        
        if (event.target.id === 'visualization_tab') {
        conceptsJsonLink.style.display = 'none';
        } else {
        conceptsJsonLink.style.display = 'flex';
        conceptsJsonLink.href = jsonLink;
        }
    }

}