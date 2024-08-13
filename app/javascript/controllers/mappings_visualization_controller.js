import { Controller } from '@hotwired/stimulus'
import { useMappingsDrawBubbles } from '../mixins/useMappingsBubbles'

export default class extends Controller {

  static values = {
    mappingsList: Object,
    zoomRatio: { type: Number, default: 1 },
    acronym: String,
    containerId: { type: String, default: 'mappings-bubbles-view' }
  }

  static targets = ['frame', 'bubbles', 'submit', 'modal', 'selector', 'ontologies', 'loader']

  connect () {

    this.drawBubbles = (mappingsList) => {
      const zoomRatio = this.zoomRatioValue
      const width = 600 * zoomRatio
      const height = 600 * zoomRatio
      const margin = 1
      const logScaleFactor = 10
      const normalization_ratio =  this.#normalizationRatio(mappingsList)

      const data = Object.entries(mappingsList).map(([key, value]) => ({
        ontology_name: key.split('/').pop(),
        ontology_mappings: value,
      }))
      this.bubblesTarget.innerHTML = ''
      useMappingsDrawBubbles(data, width, height, margin, this.bubblesTarget, normalization_ratio, logScaleFactor)

      this.#centerScroll(this.frameTarget)
    }

    this.drawBubbles(this.mappingsListValue)

    if (this.#selectionDisabled()) {
      this.#clickOnSelectedAcronymBubble()
    }

  }

  filterOntologies () {
    const selectOptions = Array.from(this.ontologiesTarget.querySelector('select').selectedOptions)
    const acronyms = selectOptions.map(option => option.value)

    const filteredList = Object.fromEntries(
      Object.entries(this.mappingsListValue).filter(([key]) => acronyms.includes(key))
    )

    this.drawBubbles(filteredList)
  }

  submit (event) {
    const itemElement = event.currentTarget.querySelector('.item')
    if (!itemElement) return

    this.submitTarget.click()

    const selectAcronym = event.currentTarget.querySelector('select').value

    const bubblesContainer = document.getElementById(this.containerIdValue)
    const selectedBubble = bubblesContainer.querySelector('[data-selected="true"]')
    const currentBubble = bubblesContainer.querySelector(`[data-acronym="${selectAcronym}"]`)

    if (selectedBubble && selectedBubble.dataset.acronym === selectAcronym) return

    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true, view: window })

    if (currentBubble && (currentBubble.getAttribute('data-enabled') === 'false' || currentBubble.getAttribute('data-highlighted') === 'true')) {
      selectedBubble.dispatchEvent(clickEvent)
    }

    if (currentBubble) currentBubble.dispatchEvent(clickEvent)
  }

  zoomIn () {
    this.zoomRatioValue++
    this.drawBubbles(this.mappingsListValue)
  }

  zoomOut () {
    if (this.zoomRatioValue > 1) {
      this.zoomRatioValue--
      this.drawBubbles(this.mappingsListValue)
    }
  }

  selectBubble (event) {
    const selected_bubble = event.currentTarget

    if (selected_bubble.getAttribute('data-enabled') === 'false') {
      // user clicks on a bubble that is disabled (has no mappings with the current bubble) do nothing
      return
    }

    this.#toggleAnimation()

    if (selected_bubble.getAttribute('data-highlighted') === 'true') {
      // user clicks on a bubble that have mapping with the current highlighted bubble, should show a modal with the mappings
      this.#showMappingsModal(selected_bubble)
      this.#toggleAnimation()
    } else if (selected_bubble.getAttribute('data-selected') === 'true') {
      // user clicks on current bubble (should deselect it, but nothing happen if we're in ontology mappings section not the page)
      this.#unSelectBubble(selected_bubble)
      this.#toggleAnimation()
    } else {
      this.#selectBubble(selected_bubble)
    }
  }

  #selectBubble (selected_bubble) {

    const acronym = selected_bubble.getAttribute('data-acronym')
    let url = '/mappings/count/' + acronym
    selected_bubble.setAttribute('data-selected', 'true')

    if (this.#selectionEnabled()) {
      const input = this.selectorTarget.querySelector('input')
      input.value = acronym
      input.dispatchEvent(new Event('input', { bubbles: true }))

      const selectValue = Array.from(this.selectorTarget.querySelectorAll('.option'))
        .find(option => option.getAttribute('data-value') === acronym)

      if (selectValue) selectValue.click()
    }

    this.#fetchMappingsDataAndSetBubblesColor(url)
  }

  #unSelectBubble (selected_bubble) {

    if (this.#selectionDisabled()) return

    selected_bubble.setAttribute('data-selected', 'false')

    const selected_circle = selected_bubble.querySelector('circle')
    selected_circle.style.fill = 'var(--primary-color)'

    const leafs = this.bubblesTarget.querySelectorAll('.leaf')
    leafs.forEach(leaf => {
      const circle = leaf.querySelector('circle')
      circle.style.fill = 'var(--primary-color)'
      circle.style.opacity = '1'
      leaf.setAttribute('data-enabled', 'true')
      leaf.setAttribute('data-highlighted', 'false')
    })
  }

  #showMappingsModal (selected_bubble) {
    const selected_leaf = this.bubblesTarget.querySelector('[data-selected="true"]')
    const acronym = selected_leaf.getAttribute('data-acronym')
    const target_acronym = selected_bubble.getAttribute('data-acronym')
    this.modalTarget.querySelector('a').href = `/mappings/show_mappings?id=${acronym}&target=${target_acronym}`
    this.modalTarget.querySelector('a').click()
  }

  #fetchMappingsDataAndSetBubblesColor (url) {
    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      },
    })
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok')
        }
        return response.json()
      })
      .then(data => {
        const mappings_list = data.map(item => ({
          acronym: item.target_ontology.acronym,
          count: item.count
        }))

        this.#setBubblesColors(mappings_list)

        this.#toggleAnimation()
      })
      .catch(error => {
        console.error('Error fetching or processing data:', error)
        // Handle errors here
      })
  }

  #setBubblesColors (mappings_list) {
    const bubblesContainer = this.bubblesTarget
    const leafs = bubblesContainer.querySelectorAll('.leaf')
    const max_mappings_count = mappings_list.reduce((max, item) => Math.max(max, item.count), -Infinity)

    leafs.forEach(leaf => {
      const circle = leaf.querySelector('circle')
      const acronym = leaf.getAttribute('data-acronym')

      const matchingMapping = mappings_list.find(item => item.acronym === acronym)

      if (matchingMapping) {
        leaf.setAttribute('data-highlighted', 'true')
        circle.style.fill = 'var(--primary-color)'

        const opacity = (matchingMapping.count / max_mappings_count + Math.log(matchingMapping.count + 1)) / 10 + 0.3
        circle.style.opacity = `${opacity}`
      } else {
        leaf.setAttribute('data-enabled', 'false')
        circle.style.fill = 'var(--light-color)'
      }
    })

    const selected_leaf = bubblesContainer.querySelector('[data-selected="true"]')
    selected_leaf.setAttribute('data-enabled', 'true')

    const selected_circle = selected_leaf.querySelector('circle')
    selected_circle.style.fill = 'var(--secondary-color)'
  }



  #centerScroll (frame) {
    frame.scrollTop = frame.scrollHeight / 2 - frame.clientHeight / 2
    frame.scrollLeft = frame.scrollWidth / 2 - frame.clientWidth / 2
  }

  #normalizationRatio (ontologies_hash) { // try to find the biggest multiple of 10 inferior to the max mappings value
    const maxValue = Math.max(...Object.values(ontologies_hash))
    let normalization_ratio = 1
    while (maxValue / normalization_ratio > 10) {
      normalization_ratio *= 10
    }
    return normalization_ratio
  }

  #toggleAnimation () {
    this.loaderTarget.classList.toggle('d-none')
    this.bubblesTarget.classList.toggle('d-none')
  }

  #selectionEnabled () {
    return !this.hasAcronymValue
  }

  #selectionDisabled () {
    return !this.#selectionEnabled()
  }

  #clickOnSelectedAcronymBubble () {
    setTimeout(() => {
      const currentBubble = this.bubblesTarget.querySelector(`[data-acronym="${this.acronymValue}"]`)
      let clickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
      })
      currentBubble.dispatchEvent(clickEvent)
    }, 100)

  }
}