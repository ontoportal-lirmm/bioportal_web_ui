export class HistoryService {

    unWantedData = ['turbo', 'controller', 'target', 'value']


    constructor() {
        this.history = History
    }

    pushState(data, title, url) {
        this.history.pushState(data, title, url)
    }

    getState() {
        return this.history.getState()
    }

    updateHistory(currentUrl, newData) {
        const newUrl = this.getUpdatedURL(currentUrl, newData)
        const newState = this.#initStateFromUrl(newUrl)
        this.pushState(newState, newState.title, newUrl)
    }

    getUpdatedURL(currentUrl, newData) {

        const url = new URL(currentUrl, document.location.origin)
        const urlParams = url.searchParams
        this.#updateURLFromState(urlParams, this.getState())

       
        this.#filterUnwantedData(newData).forEach(([updatedParam, newValue]) => {
            newValue = Array.isArray(newValue) ? newValue : [newValue]
            if (newValue !== null && Array.from(newValue).length > 0) {
                urlParams.set(updatedParam, newValue.join(','))
            }else{
                urlParams.delete(updatedParam)
            }
        })

        wantedData.forEach(([updatedParam, newValue]) => {
            if (newValue === null) {
                url.searchParams.delete(updatedParam)
            } else {
                newValue = Array.isArray(newValue) ? newValue : [newValue]
                url.searchParams.set(updatedParam, newValue.join(','))
            }
        });
    }

    #filterUnwantedData(newData) {
        const unWantedData = ['turbo', 'controller', 'target', 'value']
        return Object.entries(newData).filter(([key]) => unWantedData.filter(x => key.toLowerCase().includes(x)).length === 0)
    }

    #initStateFromUrl(currentUrl) {

    #initStateFromUrl(currentUrl) {
        const url = new URL(currentUrl, document.location.origin)
        const urlParams = url.searchParams
        let newState = this.getState().data
        urlParams.forEach((newVal, key) => {
            newState[key] = newVal
        })
        return newState
    }

    #updateURLFromState(urlParams, state) {
        let oldValue = null
        urlParams.forEach((newVal, key) => {
            oldValue = state[key]
            
            if (oldValue !== undefined && oldValue !== newVal) {
                if (newVal.length !== 0){
                    urlParams.set(key, newVal)
                }else{
                    urlParams.remove(key)
                }

            } else if (oldValue !== undefined) {
                state[key] = newVal
            }
        })
    }


}