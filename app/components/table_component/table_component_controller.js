import {Controller} from "@hotwired/stimulus"
import DataTable from 'datatables.net-dt';


// Connects to data-controller="table-component"
export default class extends Controller {
    connect(){    
        let table_component
        table_component = this.element.childNodes[1]
        let default_sort_column
        default_sort_column = parseInt(table_component.dataset.defaultsortcolumn, 10)
        
        debugger
        if (table_component.dataset.sort === 'true'){
            let table = new DataTable('#'+table_component.id, {
                paging: false,
                info: false,
                searching: false,
                autoWidth: true,
                order: [[default_sort_column, 'desc']]
            });
        }
    }
}