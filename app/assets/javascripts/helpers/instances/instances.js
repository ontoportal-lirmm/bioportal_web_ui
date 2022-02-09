class InstancesHelper {
    // function to recover the redirection link to properties tab
    static getPropertyHref(uri){
        return  `?p=properties`
    }
    // function to recover the redirection link to instances tab
    static getInstanceHref(instance_uri, class_uri = "") {
        const encodedInstanceURI = encodeURIComponent(instance_uri)
        let encodedClassURI = ""

        if(class_uri !== ""){
            encodedClassURI = encodeURIComponent(class_uri)
            return `?p=classes&conceptid=${encodedClassURI}&instanceid=${encodedInstanceURI}`
        }else {
            return `?p=instances&instanceid=${encodedInstanceURI}`
        }
    }
    // function to recover the redirection link to instances tab
    static getClassHref(uri) {
        return `?p=classes&conceptid=${encodeURIComponent(uri)}`
    }

    /**
     * Do ajax call to get an instance details (properties)
     * @param ontology{String} acronym
     * @param uri{String} an instance concept id
     * @returns {Promise<unknown>}
     */
    static  getInstanceDetailsFromURI(ontology , uri){
        return new Promise((resolve , reject) => {
            $.getJSON("/ajax/"+ontology+"/instances/"+ encodeURIComponent(uri)+"?include=all")
                .done((data) => resolve(data))
                .fail((error)=> reject(error))
        })
    }


    static setConceptId(conceptId) {
        jQuery(document).data().bp.ont_viewer.concept_id = conceptId
    }


    /**
     *
     * @param instance {Instance}
     * @returns {*}
     */
    static getLabelFrom(instance){
        let labels = instance.label
        if(Array.isArray(labels))
            labels = labels.shift()
        return  labels || instance.prefLabel || UriHelper.extractLabelFrom(instance.uri)

    }
}
