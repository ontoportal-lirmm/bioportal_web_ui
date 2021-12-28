class UriHelper {

    static extractLabelFrom(uri){
        let label = uri
        let index = uri.toString().indexOf('#')
        if (index > -1) {
            label = uri.toString().substr(index + 1)
        } else {
            index = uri.toString().lastIndexOf('/')
            if (index > -1)
                label = uri.toString().substr(index + 1)
        }
        return label
    }
    static isURI(uri){
        console.log(uri)
        return uri.startsWith("http") || uri.startsWith("https")
    }

}