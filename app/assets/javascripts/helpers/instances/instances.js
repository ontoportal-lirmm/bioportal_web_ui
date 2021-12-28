/**
 * Get a label from an uri
 * TODO: see if it's not a duplicate method
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


/**
 * Do ajax call to get an instance details (properties)
 * @param ontology{String} acronym
 * @param uri{String} an instance concept id
 * @returns {Promise<unknown>}
 */
function  getInstanceDetailsFromURI(ontology , uri){
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
function getInstanceConceptId() {
    const ont_viewer_data =  jQuery(document).data().bp.ont_viewer
    return ont_viewer_data.content_section === "instances" ? ont_viewer_data.concept_id : ""
}


function setConceptId(conceptId) {
    jQuery(document).data().bp.ont_viewer.concept_id = conceptId
}