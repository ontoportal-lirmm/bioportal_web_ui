/**
 * Get a label from an uri
 * @param uri
 * @returns {string}
 */
function getLabel(uri) {
    let label = uri
    if (isALink(uri)) { // is a link
        let index = uri.toString().indexOf('#')
        if (index > -1) {
            label = uri.toString().substr(index + 1)
        } else {
            index = uri.toString().lastIndexOf('/')
            if (index > -1)
                label = uri.toString().substr(index + 1)
        }
    }
    return label
}

function isALink(uri){
    return uri.startsWith("http") || uri.startsWith("https")
}

function  getInstanceDetailsFromURI(ontology , uri){
    return new Promise((resolve , reject) => {
        $.getJSON("/ajax/"+ontology+"/instances/"+ encodeURIComponent(uri))
            .done((data) => resolve(data))
            .fail((error)=> reject(error))
    })

}

class InstancesTable{
    constructor(tableElem , ontologyAcronym , classUri = ""){
        this.tableElem = tableElem
        this.ontologyAcronym = ontologyAcronym
        this.classUri = classUri
        this.dataTable = null
    }

    init(){
        if ( $.fn.dataTable.isDataTable( this.tableElem ) ) {
            $(this.tableElem).DataTable().destroy();

        }
        this.dataTable = $(this.tableElem).DataTable( {
            "paging": true,
            "pagingType": "full",
            "info": true,
            "searching": false,
            "ordering": false,
            "serverSide":true,
            "processing": true,
            "ajax": {
                "url": this.#getAjaxUrl(),
                "contentType": "application/json",
                "dataSrc":  (json) => {
                    json.recordsTotal = json["totalCount"];
                    json.recordsFiltered = json.recordsTotal
                    return  json["collection"].map(x => [
                        x["@id"],
                        x["types"],
                        x["properties"]
                    ])
                },
                "data": (d) => {
                    return {page: (d.start/d.length)+ 1 , pagesize: d.length}
                }
            },
            "columnDefs": this.#render(),
            "language": {
                'loadingRecords': '&nbsp;',
                'processing': `           
                                <div class="spinner-border m-2" role="status"> 
                                    <span class="sr-only">Loading...</span>
                                </div>           
                `
            },
            "createdRow":  (row, data, dataIndex ) => {
                $(row).click(() => this.#openPopUpDetail(data));
            }

        })
    }

    static mount(tableId , ontologyAcronym , conceptId){
        if(tableId.toString().length>0){
            const tableElm = document.querySelector(tableId)

            if(tableElm){
                const instanceTable = new InstancesTable( tableElm , ontologyAcronym , conceptId)
                instanceTable.init()
                return instanceTable
            }
        }
    }

    #render(){
        const toLink = function (uri) {
            return `<a id="${uri}" href="javascript:void(0)" title="${uri}">${getLabel(uri)}</a>`
        }
        const arr =["ID"];
        if(!this.#isClassURISet()){
            arr.push("Types")
        }
        return arr.map((x,i) => {
            return {
                "targets" : i ,
                "title":x,
                "render": function (data, type ,row ,meta){
                    if(typeof data === "string")
                        data = [data]
                    return data.map((x) => toLink(x)).join(',')
                }
            }
        })
    }

    #getAjaxUrl(page= null , size = null) {
        let url = "/ajax/"+ this.ontologyAcronym
        let params =  ["page="+page,"pagesize="+size].filter(x => x !== null).join("&")
        if(this.#isClassURISet() > 0){
             url += "/classes/" + encodeURIComponent(this.classUri)
        }
        url +=  "/instances" + (page!==null || size!=null ? "?"+params : "");
        return url
    }

    #isClassURISet(){
        return this.classUri.length > 0
    }

    #openPopUpDetail(data){
        $.facebox(() => {
            let uri = data[0]
            let types = data[1]
            let properties = data[2]
            
            $.facebox( new InstanceDetails(this.ontologyAcronym, uri , types , properties).render().html())
        })
    }
}


class InstanceDetails{

    constructor(ontology, uri , types , properties) {
        this.uri = uri
        this.types = types
        this.properties = properties
        this.ontology = ontology
    }

    render(){
        console.log("render details")
        console.log(this)
        const toLink = function (uri, href) {
            if(isALink(uri))
                return `<a id="${uri}" href="${href}" title="${uri}" target="_blank">${getLabel(uri)}</a>`
            else
                return uri
        }
        const getPropertyHref = function (uri){
            return  `?p=properties`
        }
        const getInstanceHref = function (uri) {
            return `?p=instances&conceptid=${encodeURIComponent(uri)}`
        }
        const getClassHref = function (uri) {
            return `?p=classes&conceptid=${encodeURIComponent(uri)}`
        }

        let container = $(`<div>
                    <h4>Details of  ${toLink(this.uri , "javascript:void(0)")} of type : ${this.types.map(x => toLink(x , getClassHref(x)))}</h4>
            </div>`)
        let table = $(`<table class='zebra' style='width: 100% ; min-width: 60vw'>
                    <thead>
                            <tr>
                                <th>Property name</th>    
                                <th>Property value</th>    
                            </tr>
                    </thead>
            </table>`)

        let tbody = $(`<tbody></tbody>`)
        delete this.properties["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]
        Object.entries(this.properties).forEach((x) => {
            let row = `<tr><td>${toLink(x[0], getPropertyHref(x[0]))}</td><td>${x[1].map(x => toLink(x,getInstanceHref(x))).join(',')}</td></tr>`
            tbody.append(row)
        })
        table.append(tbody)
        container.append(table)
        return container
    }

}