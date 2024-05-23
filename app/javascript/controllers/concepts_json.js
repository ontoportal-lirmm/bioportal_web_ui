import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        ontologyId: String,
        conceptId: String,
        apiKey: String
      }

    update(){
        const baseClassUrl = `${this.ontologyIdValue}/classes/${this.conceptIdValue}`;
        const apikey = `apikey=${this.apiKeyValue}`;
        const tabsList = document.querySelectorAll('#concept_tabs_container .nav-item');
        const links = {
            details_tab: `${baseClassUrl}?${apikey}&display=all`,
            instances_tab: `${baseClassUrl}/instances?${apikey}`,
            notes_tab: `${baseClassUrl}/notes?${apikey}`,
            mappings_tab: `${baseClassUrl}/mappings?${apikey}`,
            visualization_tab: ''
        };

        let selectedItemId;
        for (let i = 0; i < tabsList.length; i++) {
            if (tabsList[i].classList.contains('active')) {
                selectedItemId = tabsList[i].querySelector('a').id;
                break;
            }
        }

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