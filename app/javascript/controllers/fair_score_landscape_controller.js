import { Controller } from "@hotwired/stimulus"
import { FairScoreChartContainer, FairScoreCriteriaBar } from "../mixins/useFairScore";
// Connects to data-controller="fair-score-landscape"
export default class extends Controller {
  connect(){
    let fairCriteriaBars = new FairScoreCriteriaBar('ont-fair-scores-criteria-bars-canvas')
    let fairContainer = new FairScoreChartContainer('fair-score-charts-container' , [fairCriteriaBars])
    fairContainer.getFairScoreData("all")
  }
  
  update(event){
    let selected_ontologies = event.target.selectedOptions
    let fairCriteriaBars = new FairScoreCriteriaBar('ont-fair-scores-criteria-bars-canvas')
    let fairContainer = new FairScoreChartContainer('fair-score-charts-container' , [fairCriteriaBars])
    let ontologies = []
    for(let i=0; i<selected_ontologies.length; i++){
      ontologies.push(selected_ontologies[i].value)
    }
    if(ontologies != []){
      fairContainer.getFairScoreData(ontologies.join(','))
    } else {
      fairContainer.getFairScoreData("all")
    }
    e.preventDefault()
  }
}
