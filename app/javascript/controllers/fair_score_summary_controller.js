import { Controller } from "@hotwired/stimulus"
import {FairScorePrincipleBar, FairScoreCriteriaRadar, FairScoreChartContainer} from "../mixins/useFairScore";
// Connects to data-controller="fair-score-summary"
export default class extends Controller {
  connect() {
    let fairScoreBar = new FairScorePrincipleBar( 'ont-fair-scores-canvas')
    let fairScoreRadar = new FairScoreCriteriaRadar(  'ont-fair-criteria-scores-canvas')
    let fairContainer = new FairScoreChartContainer('fair-score-charts-container' , [   fairScoreRadar , fairScoreBar])

    fairContainer.getFairScoreData(window.location.pathname.split('/')[2])
  }
}
