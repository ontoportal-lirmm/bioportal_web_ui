/**
 * A web components that render a jquery data table of an ontology (and class) instances inside a <table> element
 */
class InstancesTable extends DataTable {


    get ontologyAcronym() {
        return this.getAttribute("ontology-acronym") || ""
    }

    get classUri() {
        return this.getAttribute("class-uri") || ""
    }

    get config() {
        return {
            "paging": true,
            "pagingType": "full",
            "info": true,
            "searching": true,
            "ordering": false,
            "serverSide": true,
            "processing": true,
            "ajax": {
                "url": this.getAjaxUrl(),
                "contentType": "application/json",
                "dataSrc": (json) => {
                    json.recordsTotal = json["table"]["totalCount"]
                    json.recordsFiltered = json.recordsTotal
                    return json["table"]["collection"].map(x => [
                        {
                            id: x["table"]["@id"],
                            label: x["table"]["label"],
                            prefLabel: x["table"]["prefLabel"],
                            labelToPrint: x["table"]["labelToPrint"],
                            ontology: x["table"]["ontology"]
                        },
                        x["table"]["types"],
                        x["table"]["properties"]
                    ])
                },
                error:  (e) => {
                    console.log("instances ajax call error: " + e.statusText)
                },
                "data": (d) => {
                    //return parameters to send for the server
                    let columns = d.columns
                    let sortby = (d.order[0] ? columns[d.order[0].column].name : "")
                    let order = (d.order[0] ? d.order[0].dir : "")
                    return {
                        page: (d.start / d.length) + 1,
                        pagesize: d.length,
                        search: d.search.value,
                        sortby, order
                    }
                }
            },
            "columnDefs": this.render(),
            "language": {
                'loadingRecords': '&nbsp;',
                'processing': new DataTableLoader(),
                "search": "Search by labels:"
            }

        }
    }

    constructor() {
        super()
    }

    connectedCallback() {
        super.connectedCallback()
    }

    update(ontologyAcronym, classUri) {
        this.setAttribute("ontology-acronym", ontologyAcronym)
        this.setAttribute("class-uri", classUri)
        super.initDataTable()
    }

    render() {

        let columns = [{
            "targets": 0,
            "name": "label",
            "title": 'Instance',
            "render": (data) => {
                const {id, labelToPrint, ontology} = data
                return `<a id="${id}" data-controller="show-modal"  data-turbo="true"  data-show-modal-title-value="${labelToPrint}" data-turbo-frame="application_modal_content" data-action="click->show-modal#show" href="/ontologies/${ontology}/instances/fake_id?id=${encodeURIComponent(id)}">${labelToPrint}</a>`
            }
        }]

        if (!this.isClassURISet())
            columns.push({
                "targets": 1,
                "name": "types",
                "title": 'Types',
                "render": (data) => data.map(x => {
                    const id = x.type
                    const label = x.labelToPrint
                    const acronym = x.ontology
                    const href = (id === label ? id : `?p=classes&conceptid=${encodeURIComponent(id)}`)
                    return `<a id="${id}" href="${href}" target="_blank">${label}</a>`
                })
            })

        return columns
    }


    getAjaxUrl() {
        let url = "/ajax/" + this.ontologyAcronym
        if (this.isClassURISet() > 0) {
            url += "/classes/" + encodeURIComponent(this.classUri)
        }
        url += "/instances"
        return url
    }

    isClassURISet() {
        return this.classUri.length > 0
    }


}