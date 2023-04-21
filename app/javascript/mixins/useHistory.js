export class HistoryService {

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
        const state = this.#initStateFromUrl(currentUrl)
        const newUrl = this.getUpdatedURL(currentUrl, newData, state)
        this.pushState(state, state.title, newUrl)
    }

    getUpdatedURL(currentUrl, newData) {
        const url = new URL(currentUrl, document.location.origin)
        const urlParams = url.searchParams
        this.#updateURLFromState(urlParams, this.getState())


        this.#filterUnwantedData(newData).forEach(([updatedParam, newValue]) => {
                newValue = Array.isArray(newValue) ? newValue : [newValue]
                if (newValue !== null && Array.from(newValue).length > 0) {
                    urlParams.set(updatedParam, newValue.join(','))
                }
            })

        return url.pathname + url.search
    }

    #filterUnwantedData(newData){
        const unWantedData = ['turbo', 'controller', 'target', 'value']
        return Object.entries(newData).filter(([key]) =>  unWantedData.filter(x => key.toLowerCase().includes(x)).length === 0)
    }
    #initStateFromUrl(currentUrl) {

        const url = new URL(currentUrl, document.location.origin)
        const urlParams = url.searchParams
        const oldState = this.getState().data
        let newState = oldState
        let oldValue = null
        urlParams.forEach((newVal, key) => {
            oldValue = oldState[key]
            if (oldValue === undefined) {
                newState[key] = newVal
            }
        })
        return newState
    }

    #updateURLFromState(urlParams, state) {
        let oldValue = null
        urlParams.forEach((newVal, key) => {
            oldValue = state[key]
            if (oldValue !== undefined && oldValue !== newVal) {
                urlParams.set(key, newVal)
            } else if (oldValue !== undefined) {
                state[key] = newVal
            }
        })
    }


}