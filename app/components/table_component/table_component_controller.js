import {Controller} from "@hotwired/stimulus"
import DataTable from 'datatables.net-dt';


// Connects to data-controller="table-component"
export default class extends Controller {
    static values = {
        sortcolumn: String,
        paging: Boolean,
        searching: Boolean,
        noinitsort: Boolean
    }
    connect(){    
        let table_component
        table_component = this.element.childNodes[1]
        let default_sort_column
        default_sort_column = parseInt(this.sortcolumnValue, 10)
        if (this.sortValue || this.searchingValue || this.pagingValue){
            let table = new DataTable('#'+table_component.id, {
                paging: this.pagingValue,
                info: false,
                searching: this.searchingValue,
                autoWidth: true,
                order: this.noinitsortValue ? [] : [[default_sort_column, 'desc']]
            });
        }
    }
}