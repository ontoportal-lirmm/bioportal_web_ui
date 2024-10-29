import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="skos-collection-colors"
export default class extends Controller {

  static values = {
    collectionsColorSelectTarget: String
  }
  static targets = ['collection']

  connect () {
    this.allCollections = this.#collectionsChoices()
    this.selected = []
  }

  updateCollectionTags (event) {
    this.selected = Object.entries(event.detail.data)[0][1]
    this.collectionTargets.forEach((collectionElem) => {
      this.#updateColorsTags(collectionElem)
    })
  }

  #updateColorsTags (collectionElem) {
    let collections = this.#getElemCollections(collectionElem)
    let activeCollections = this.#getMatchedCollections(collectionElem, collections, this.selected)

    this.#removeColors(collectionElem)
    this.#addColorsTags(collectionElem, this.#getCollections(activeCollections))
  }

  collectionTargetConnected (collectionElem) {

    if (this.selected.length > 0) {
      this.#updateColorsTags(collectionElem)
    }
  }

  #removeColors (collectionElem) {
    const childList = collectionElem.children
    if (childList && childList.length > 0) {
      collectionElem.removeChild(collectionElem.lastElementChild)
    }
  }

  #collectionsChoices () {
    const options = document.getElementById(this.collectionsColorSelectTargetValue)
    const out = {}
    if (options) {
      Array.from(options.options).forEach(s => {
        if (s.value !== '') {
          out[s.value] = {
            color: s.dataset.color,
            title: s.textContent
          }
        }
      })
    }
    return out
  }

  #getMatchedCollections (elem, collections, selected) {
    collections = [...new Set(collections.concat(this.#getElemActiveCollections(elem)))]
    return selected.filter(c => collections.includes(c))
  }

  #getCollections(collectionsIds) {
    return Object.entries(this.allCollections).filter(([key]) => collectionsIds.includes(key))
  }



  #getElemCollections (elem) {
    return JSON.parse(elem.dataset.collectionsValue)
  }

  #getElemActiveCollections (elem) {
    return JSON.parse(elem.dataset.activeCollectionsValue)
  }

  #addColorsTags (elem, collections) {
    const colorsContainer = document.createElement('span')
    collections.forEach(c => this.#elemAddColorTag(colorsContainer, c[1].title, c[1].color))
    elem.appendChild(colorsContainer)
  }

  #elemAddColorTag (elem, title, color) {
    const span = document.createElement('span')
    span.dataset.controller = 'tooltip'
    span.title = title
    span.style.backgroundColor = color
    span.style.height = '10px'
    span.style.width = '10px'
    span.style.borderRadius = '50%'
    span.style.display = 'inline-block'
    span.className += 'mx-1'

    elem.appendChild(span)
  }
}
