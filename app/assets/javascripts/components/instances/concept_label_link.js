class ConceptLabelLink {
    static render(conceptId , href , target="" , label=""){
        label ||= UriHelper.extractLabelFrom(conceptId)
        return `<a id="${conceptId}" href="${href}" title="${conceptId}" target="${target}">${label}</a>`
    }
}