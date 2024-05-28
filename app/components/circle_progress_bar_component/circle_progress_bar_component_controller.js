import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="circle-progress-bar"
export default class extends Controller {
  static targets = ['percentage', 'innerCircle']
  static values = {
    percentage: Number,
    progressColor: String,
    bgColor: String,
    circleColor: String
  }

  connect() {
    const progressBar = this.element;
    const progressValue = this.percentageTarget;
    const innerCircle = this.innerCircleTarget;
    let startValue = 0,
        endValue = this.percentageValue,
        speed = 30,
        progressColor = this.progressColorValue;

    const progress = setInterval(() => {
      startValue++;
      progressValue.textContent = `${startValue}%`;
      progressValue.style.color = `${progressColor}`;

      innerCircle.style.backgroundColor = `${this.circleColorValue}`;

      progressBar.style.background = `conic-gradient(${progressColor} ${
          startValue * 3.6
      }deg,${this.bgColorValue} 0deg)`;
      if (startValue === endValue) {
        clearInterval(progress);
      }
    }, speed);
  }
}
