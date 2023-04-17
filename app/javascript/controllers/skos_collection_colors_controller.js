import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="skos-collection-colors"
export default class extends Controller {

    static values = {
        collectionsColorSelectTarget: String
    }
    static targets = ['collection']


    connect() {
        this.allCollections = this.#collectionsChoices()
        this.selected = []
    }

    updateCollectionTags(event) {
        this.selected = Object.entries(event.detail.data)[0][1]
        this.collectionTargets.forEach((collectionElem) => {
            this.#updateColorsTags(collectionElem)
        })
    }

    #updateColorsTags(collectionElem) {
        let collections = this.#getElemCollections(collectionElem)
        let activeCollections = this.#getMatchedCollections(collectionElem, collections, this.selected)

        this.#removeColors(collectionElem)
        this.#addColorsTags(collectionElem, this.#getCollectionColors(activeCollections))
    }


    collectionTargetConnected(collectionElem) {
        if (this.selected.length > 0) {
            this.#updateColorsTags(collectionElem)
        }
    }

    #removeColors(collectionElem) {
        const childList = collectionElem.children
        if (childList && childList.length > 1) {
            collectionElem.removeChild(collectionElem.lastElementChild)
        }
    }

    #collectionsChoices() {
        const options = document.getElementById(this.collectionsColorSelectTargetValue)
        const out = {}
        if (options) {
            Array.from(options.options).forEach(s => {
                if (s.value !== '') {
                    out[s.value] = s.dataset.color
                }
            })
        }
        return out
    }

    #getMatchedCollections(elem, collections, selected) {
        collections = [...new Set(collections.concat(this.#getElemActiveCollections(elem)))]
        return selected.filter(c => collections.includes(c))
    }

    #getCollectionColors(collectionsIds) {
        return Object.entries(this.allCollections).filter(([key]) => collectionsIds.includes(key)).map(x => x[1])
    }


    #getElemCollections(elem) {
        return JSON.parse(elem.dataset.collectionsValue)
    }

    #getElemActiveCollections(elem) {
        return JSON.parse(elem.dataset.activeCollectionsValue)
    }

    #addColorsTags(elem, colors) {
        const colorsContainer = document.createElement('span')
        colors.forEach(c => this.#elemAddColorTag(colorsContainer, c))
        elem.appendChild(colorsContainer)
    }

    #elemAddColorTag(elem, color) {
        const span = document.createElement('span')
        span.style.backgroundColor = color
        span.style.height = '10px'
        span.style.width = '10px'
        span.style.borderRadius = '50%'
        span.style.display = 'inline-block'
        span.className += 'mx-1'
        elem.appendChild(span)
    }
}
