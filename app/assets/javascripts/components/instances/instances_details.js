/**
 * Render an instance properties in the form of a sample table
 */
class InstanceDetails{

    /**
     *
     * @param ontology {String}
     * @param instance {Instance}
     */
    constructor(ontology, instance) {
        this.instance = instance
        this.ontology = ontology
    }

    render(){

        const instanceLabel = InstanceLabelLink.render(this.instance, "","_blank" )
        const classesLabels = this.instance.types.map(x => AjaxConceptLabelLink.render(this.ontology, x), "_blank")
        const propertyLabel = (x) => ConceptLabelLink.render(x , InstancesHelper.getPropertyHref(x))
        const propertyValueLabel = (stringValue) => {
            if(UriHelper.isURI(stringValue))
                return ConceptLabelLink.render(stringValue , InstancesHelper.getInstanceHref(stringValue ,"root") , "_blank")
            else
                return stringValue
        }
        let properties = this.instance.properties
        let container = $(`<div>
                    <h4>Details of  ${instanceLabel} of type : ${classesLabels}</h4>
            </div>`)
        let table = $(`<table class='zebra' style='min-width: 60vw; max-width: 90vw'>
                    <thead>
                            <tr>
                                <th>Property name</th>    
                                <th>Property value</th>    
                            </tr>
                    </thead>
            </table>`)

        let tbody = $(`<tbody></tbody>`)
        delete properties["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]
        Object.entries(properties).forEach((x) => {
            let row = `<tr><td>${propertyLabel(x[0])}</td><td style="word-break: break-all">${x[1].map(x => propertyValueLabel(x)).join(',')}</td></tr>`
            tbody.append(row)
        })
        table.append(tbody)
        container.append(table)
        return container
    }

}