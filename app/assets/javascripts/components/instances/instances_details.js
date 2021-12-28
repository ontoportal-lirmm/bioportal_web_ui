/**
 * Render an instance properties in the form of a sample table
 */
class InstanceDetails{

    constructor(ontology, uri , types , properties) {
        this.uri = uri
        this.types = types
        this.properties = properties
        this.ontology = ontology
    }

    render(){

        const instanceLabel = ConceptLabelLink.render(this.uri , InstancesHelper.getInstanceHref(this.uri) , "_blank")
        const classesLabels = this.types.map(x => AjaxConceptLabelLink.render(this.ontology, x), "_blank")
        const propertyLabel = (x) => ConceptLabelLink.render(x , InstancesHelper.getPropertyHref(x))
        const propertyValueLabel = (x) => (UriHelper.isURI(x) ? ConceptLabelLink.render(x , InstancesHelper.getInstanceHref(x) , "_blank") : x)

        let container = $(`<div>
                    <h4>Details of  ${instanceLabel} of type : ${classesLabels}</h4>
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
            let row = `<tr><td>${propertyLabel(x[0])}</td><td>${x[1].map(x => propertyValueLabel(x)).join(',')}</td></tr>`
            tbody.append(row)
        })
        table.append(tbody)
        container.append(table)
        return container
    }

}