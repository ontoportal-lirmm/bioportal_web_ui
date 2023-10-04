import { Controller } from "@hotwired/stimulus"
import { FairScoreChartContainer, FairScoreCriteriaBar } from "../mixins/useFairScore";
// Connects to data-controller="fair-score-landscape"
export default class extends Controller {
  connect() {
    let fairCriteriaBars = new FairScoreCriteriaBar('ont-fair-scores-criteria-bars-canvas')
    let fairContainer = new FairScoreChartContainer('fair-score-charts-container' , [fairCriteriaBars])
    let ontologies = jQuery("#ontology_ontologyId");

    fairContainer.getFairScoreData("all")
    ontologies.change( (e) => {
      if(ontologies.val() !== null){
        fairContainer.getFairScoreData(ontologies.val().join(','))
      } else if(ontologies.val() === null){
        fairContainer.getFairScoreData("all")
      }
      e.preventDefault()
    })
  }
}
