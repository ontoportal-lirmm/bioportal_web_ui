import { Controller } from '@hotwired/stimulus'
import { useAgentSubmissionsDrawBubbles } from '../mixins/useAgentSubmissionsBubbles'

export default class extends Controller {

  static values = {
    ontologiesList: Object,
    uiUrl: String,
    zoomRatio: { type: Number, default: 1 },
    acronym: String,
    containerId: { type: String, default: 'agent-submissions-bubbles-view' }
  }

  static targets = ['frame', 'bubbles', 'submit', 'modal', 'selector', 'ontologies', 'loader']

  connect () {
    this.drawBubbles = (ontologiesList) => {
      const zoomRatio = this.zoomRatioValue
      const width = 580 * zoomRatio
      const height = 580 * zoomRatio
      const margin = 1
      const logScaleFactor = 10
      const normalization_ratio =  this.#normalizationRatio(ontologiesList)

      const data = Object.entries(ontologiesList).map(([key, value]) => ({
        ontology_name: key.split('/').pop(),
        role : value,
        ontology_bubble_size: this.getRndInteger(2,5),
      }))
      this.bubblesTarget.innerHTML = ''
      useAgentSubmissionsDrawBubbles(data, width, height, margin, this.bubblesTarget, normalization_ratio, logScaleFactor)
    }
    this.drawBubbles(this.ontologiesListValue) 
  }
  getRndInteger(min, max) {
    return Math.floor(Math.random() * (max - min) ) + min;
  }

  selectBubble (event) {
    const selected_bubble = event.currentTarget
    this.#openOntologyInNewTab(selected_bubble.dataset.acronym)
  }

  #openOntologyInNewTab(acronym) {
    const ontologyUrl = this.uiUrlValue + "/ontologies/" + acronym
    if (ontologyUrl) {
      window.open(ontologyUrl, '_blank')
    } else {
      console.warn(`No URL found for ontology: ${acronym}`)
    }
  }

  #normalizationRatio (ontologies_hash) { // try to find the biggest multiple of 10 inferior to the max mappings value
    const maxValue = Math.max(...Object.values(ontologies_hash))
    let normalization_ratio = 1
    while (maxValue / normalization_ratio > 10) {
      normalization_ratio *= 10
    }
    return normalization_ratio
  }
}