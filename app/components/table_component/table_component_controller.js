  import { Controller } from "@hotwired/stimulus"
  import DataTable from 'datatables.net-dt'

  // Connects to data-controller="table-component"
  export default class extends Controller {
    static values = {
      sortcolumn: String,
      paging: Boolean,
      searching: Boolean,
      noinitsort: Boolean,
      searchPlaceholder: { type: String, default: 'Search' },
      serverSide: Boolean,
      ajaxUrl: String,
      columns: Array
    }

    connect() {
      const table = this.element.querySelector('table')
      const defaultSortColumn = parseInt(this.sortcolumnValue, 10)

      if (this.sortcolumnValue || this.searchingValue || this.pagingValue || this.serverSideValue) {
      
        this.table = new DataTable(`#${table.id}`, {
          paging: this.pagingValue,
          columns: this.columnsValue.map(name => ({ data: name })),
          info: false,
          lengthMenu: [
            [10, 25, 50, 100],
            [10, 25, 50, 100]
          ],
          searching: this.searchingValue,
          autoWidth: true,
          serverSide: this.serverSideValue,
          processing: true,
          ajax: this.serverSideValue ? {
            url: this.ajaxUrlValue,
            data: function (d) {
              return {
                page: Math.floor(d.start / d.length) + 1,
                pagesize: d.length,
                search: d.search.value 
              }
            },
            dataSrc: function (json) {
              return json.collection || []

            }
          } : null,
          order: this.noinitsortValue ? [] : [[defaultSortColumn, 'desc']],
          search: {
            return: true
          },
          language: {
            search: '_INPUT_',
            searchPlaceholder: this.searchPlaceholderValue
          }
        })

        
      }
    }
  }
