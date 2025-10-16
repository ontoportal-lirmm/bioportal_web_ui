// app/javascript/controllers/subjects_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "searchWrapper"]

  addResult(event) {
    event.preventDefault()
    const target = event.currentTarget

    const uriSpan = target.querySelector('.class-uri')
    const labelSpan = target.querySelector('.class-label_name')
    if (!uriSpan || !labelSpan) return

    const uri = uriSpan.textContent.trim()

    // ✅ Count ALL .nested-form-input-row in the entire form (or page)
    const existingRows = document.querySelectorAll('.nested-subjects-form-input-row')
    const nextIndex = existingRows.length

    // Create new hidden input (or visible, as you prefer)
    const input = document.createElement("input")
    input.type = "text"
    input.name = `submission[hasDomain][${nextIndex}]`
    input.value = uri
    input.readOnly = true
    input.className = "form-control"
    input.style.fontSize = "13px";
    const row = document.createElement("div")
    row.className = "nested-subjects-form-input-row"
    row.appendChild(input)

    // Append to the same container where other rows live
    // We find it by looking for a common parent (e.g., the nested form wrapper)
    const formWrapper = this.element
    if (formWrapper) {
      // Insert before the "Add" button or at the end of the list
      formWrapper.appendChild(row)
    }

    // Remove search UI
    if (this.hasSearchWrapperTarget) {
      this.searchWrapperTarget.remove()
    }
  }
}
