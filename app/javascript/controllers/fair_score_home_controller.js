import { Controller } from "@hotwired/stimulus"
import {FairScorePrincipleBar, FairScoreCriteriaRadar, FairScoreChartContainer} from "../mixins/useFairScore";
// Connects to data-controller="fair-score-home"
export default class extends Controller {
  connect() {
    let fairScoreBar = new FairScorePrincipleBar( 'ont-fair-scores-canvas')
    let fairScoreRadar = new FairScoreCriteriaRadar(  'ont-fair-criteria-scores-canvas')
    let fairContainer = new FairScoreChartContainer('fair-score-charts-container' , [   fairScoreRadar , fairScoreBar])
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
