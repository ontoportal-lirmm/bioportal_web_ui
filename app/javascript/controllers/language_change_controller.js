import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="language-change"
export default class extends Controller {

  changeContentLanguage() {
    const lang = this.element.value
    var urlSearchParams = new URLSearchParams(window.location.search);
    if (urlSearchParams.has('language')) {
        urlSearchParams.set('language', lang);
    } else {
        urlSearchParams.append('language', lang);
    }
    var newUrl = window.location.origin + window.location.pathname + '?' + urlSearchParams.toString();
    window.location.href = newUrl;
  }
}
