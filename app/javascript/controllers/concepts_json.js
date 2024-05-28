import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        classUrl: String,
        apiKey: String
      }

    update(){
        const baseClassUrl = this.classUrlValue;
        const apikey = `apikey=${this.apiKeyValue}`;
        const tabsList = document.querySelectorAll('#concept_tabs_container .nav-item');
        const links = {
            details_tab: `${baseClassUrl}?${apikey}&display=all`,
            instances_tab: `${baseClassUrl}/instances?${apikey}`,
            notes_tab: `${baseClassUrl}/notes?${apikey}`,
            mappings_tab: `${baseClassUrl}/mappings?${apikey}`,
            visualization_tab: ''
        };

        const selectedItemId = Array.from(tabsList).find(tab => tab.classList.contains('active'))?.querySelector('a').id; 

        const jsonLink = links[selectedItemId];
        const conceptsJsonLink = document.querySelector('#concepts_json_link a');
        
        if (event.target.id === 'visualization_tab') {
        conceptsJsonLink.style.display = 'none';
        } else {
        conceptsJsonLink.style.display = 'flex';
        conceptsJsonLink.href = jsonLink;
        }
    }

}