import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
    static values = {
        multiple: { type: Boolean, default: false },
        openAdd : { type: Boolean, default: false }.
        withIcon : { type: Boolean, default: false },
        valueField: { type: String, default: 'id' },
        searchField: { type: String, default: 'title' },
        options: { type: Array, default: [] }
    }


    connect() {
        let myOptions = {}
        
        if (this.withIconValue) {

            myOptions = {
                valueField: this.valueFieldValue,
                searchField: this.searchFieldvalue,
                options: this.optionsValue,
                render: {
                    option: (data, escape) => {
                        return '<div>' +
                                '<span class="title">' + escape(data.title) + '</span>' +
                                '<span class="url">' + escape(data.url) + '</span>' +
                            '</div>';
                    },
                    item: (data, escape) => {
                        return '<div title="' + escape(data.url) + '">' + escape(data.title) + '</div>';
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