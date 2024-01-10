import {Controller} from "@hotwired/stimulus"
import DataTable from 'datatables.net-dt';


// Connects to data-controller="recommender"
export default class extends Controller {
    connect(){
        console.log('bilel')
        let table = new DataTable('#recommender-table', {
            paging: false, // Disable pagination
            info: false, // Disable info display
            searching: false,
            autoWidth: true
          });
        table.columns.adjust().draw();
    }
}