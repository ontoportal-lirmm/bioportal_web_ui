import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="community"
export default class extends Controller {
  static targets = [ "vote"]
  
  up(e) {
    const voteButton = this.voteTarget;
    const count = voteButton.querySelector('.count');
  
    this.#updateButtonStyle(voteButton, 'var(--primary-color)', 0);
    this.#updateCount(count, 1);
  }
  
  down(e) {
    const voteButton = this.voteTarget;
    const count = voteButton.querySelector('.count');
  
    this.#updateButtonStyle(voteButton, 'var(--secondary-color)', 1);
    this.#updateCount(count, -1);
  }

  #updateButtonStyle(voteButton, color, fillPathIndex) {
    voteButton.style.background = color;
    voteButton.style.color = 'white';
  
    const paths = voteButton.querySelectorAll('svg path');
    paths.forEach(path => (path.style.stroke = 'white'));
    paths[fillPathIndex].style.fill = 'white';
  }
  
  #updateCount(count, change) {
    const value = count.textContent.trim();
    if (value === 'Vote') {
      count.textContent = change > 0 ? '1' : '-1';
    } else if (value === (change > 0 ? '-1' : '1')) {
      count.textContent = 'Vote';
    } else {
      count.textContent = parseInt(value) + change;
    }
  }
  


}
