class Instance {
    constructor(uri , label , prefLabel , types=[] , properties = []) {
        this.uri = uri
        this.label = label
        this.prefLabel = prefLabel
        this.types = types
        this.properties = properties
    }
}