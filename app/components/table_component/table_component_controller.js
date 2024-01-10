import {Controller} from "@hotwired/stimulus"
import DataTable from 'datatables.net-dt';


// Connects to data-controller="table-component"
export default class extends Controller {
    connect(){    
        let table_component
        table_component = this.element.childNodes[1]
        if (table_component.dataset.sort === 'true'){
            let table = new DataTable('#'+table_component.id, {
                paging: false,
                info: false,
                searching: false,
                autoWidth: true
            });
        }
    }
}