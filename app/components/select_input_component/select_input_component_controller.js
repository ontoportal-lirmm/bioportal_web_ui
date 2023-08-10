import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
    static values = {
        multiple: { type: Boolean, default: false },
        openAdd : { type: Boolean, default: false },
        withIcon : { type: Boolean, default: false },
        valueField: { type: String, default: 'id' },
        searchField: { type: String, default: 'title' },
        options: { type: Array, default: [] }
    };


    connect() {
        let myOptions = {}

        
        if (this.withIconValue) {
            myOptions = {
                valueField: this.valueFieldValue,
                searchField: this.searchFieldValue,
                options: this.optionsValue,
                render: {
                    option: (data, escape) => {
                        return `<div>
                                <span class="${escape(data.icon)}"></span>
                                <span class="title ml-2">${escape(data.title)}</span>  
                                </div>`;
                    },
                    item: (data, escape) => {
                        return `<div title="${escape(data.id)}">
                                <span class="${escape(data.icon)}"></span>
                                <span class="title ml-2">${escape(data.title)}</span>  
                            </div>`;
                    }
                }
            }


        } else {
            if (this.multipleValue) {
                myOptions['plugins'] = ['remove_button'];
            }
            if (this.openAddValue) {
                myOptions['create'] = true;
            }
        }
        
        
        
        
       
        new TomSelect(this.element, myOptions);
    }

}