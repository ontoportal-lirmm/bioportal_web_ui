import {Controller} from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
    static values = {
        multiple: {type: Boolean, default: false},
        openAdd: {type: Boolean, default: false}
    };


    connect() {
        let myOptions = {}

        myOptions = {
            create: true,
            render: {
                option: (data) => {
                    return `<div> ${data.text} </div>`
                },
                item: (data) => {
                    return `<div> ${data.text} </div>`
                }
            }
        }

        if (this.multipleValue) {
            myOptions['plugins'] = ['remove_button'];
        }

        if (this.openAddValue) {
            myOptions['create'] = true;
        }

        new TomSelect(this.element, myOptions);
    }

}