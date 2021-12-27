/**
 * Render an instance properties in the form of a table
 */
class InstanceDetails{

    constructor(ontology, uri , types , properties) {
        this.uri = uri
        this.types = types
        this.properties = properties
        this.ontology = ontology
    }

    render(){
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