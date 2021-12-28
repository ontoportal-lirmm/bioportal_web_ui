function ajaxGetClassLabelLink(ontologyAcronym, conceptId ,  target="") {
    return `<a id="${conceptId}" href="${getClassHref(conceptId)}" target="${target}">${conceptId}</a>`
}

class ConceptLabelLink {
    static render(conceptId , href , target="" , label=""){
        label ||= UriHelper.extractLabelFrom(conceptId)
        return `<a id="${conceptId}" href="${href}" title="${conceptId}" target="${target}">${label}</a>`
    }
}