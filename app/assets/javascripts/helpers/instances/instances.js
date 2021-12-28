class InstancesHelper {
    // function to recover the redirection link to properties tab
    static getPropertyHref(uri){
        return  `?p=properties`
    }
    // function to recover the redirection link to instances tab
    static getInstanceHref(uri) {
        return `?p=instances&conceptid=${encodeURIComponent(uri)}`
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
            $.getJSON("/ajax/"+ontology+"/instances/"+ encodeURIComponent(uri))
                .done((data) => resolve(data))
                .fail((error)=> reject(error))
        })
    }

    /**
     * Return the conceptid from
     * the section url if the section is "instances"
     * @returns {*|string}
     */
    static getInstanceConceptId() {
        const ont_viewer_data =  jQuery(document).data().bp.ont_viewer
        const concept_id = ont_viewer_data.concept_id
        return ont_viewer_data.content_section === "instances" ? (concept_id === "root" ? "" :concept_id)  : ""
    }


    static setConceptId(conceptId) {
        jQuery(document).data().bp.ont_viewer.concept_id = conceptId
    }
}
