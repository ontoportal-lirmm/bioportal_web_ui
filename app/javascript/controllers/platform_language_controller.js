import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails";
import { getCookie } from "../mixins/cookie";

// Connects to data-controller="platform-language"
// this controller is used to change the language of the whole platform
export default class extends Controller {

  connect() {
    const locale = getCookie('locale');

    const option = document.querySelector(`#language-select option[value="${locale}"]`);
    option && (option.selected = true);

  }

  handleLangChanged(event) {
    const userPreferedLanguage = event.target.value;
    Turbo.visit(`/locale/${userPreferedLanguage}`, { action: "replace" });
  }
}
