import { Controller } from '@hotwired/stimulus'
// Connects to data-controller="simple-tree"
export default class extends Controller {

  static values = {
    autoClick: { type: Boolean, default: false }
  }

  connect () {
    let activeElem = this.element.querySelector('a.active')
    if (activeElem) {
      $(this.element).scrollTo($(activeElem))

      if (this.autoClickValue) {
        activeElem.click()
      }
    }
    this.#onClickTooManyChildrenInit()
  }

  select (event) {
    this.element.querySelector('a.active')?.classList.toggle('active')
    event.currentTarget.classList.toggle('active')
    this.#afterClick(event.currentTarget)
  }

  toggleChildren (event) {
    event.preventDefault()
    event.target.classList.toggle('fa-chevron-right')
    event.target.classList.toggle('fa-chevron-down')
    event.target.nextElementSibling.nextElementSibling.classList.toggle('hidden')
  }

  #onClickTooManyChildrenInit () {
    jQuery('.too_many_children_override').live('click', (event) => {
      event.preventDefault()
      let result = jQuery(event.target).closest('ul')
      result.html('<img src=\'/images/tree/spinner.gif\'>')
      jQuery.ajax({
        url: jQuery(event.target).attr('href'),
        context: result,
        success: function (data) {
          this.html(data)
          this.simpleTreeCollection.get(0).setTreeNodes(this)
        },
        error: function () {
          this.html('<div style=\'background: #eeeeee; padding: 5px; width: 80%;\'>Problem getting children. <a href=\'' + jQuery(this).attr('href') + '\' class=\'too_many_children_override\'>Try again</a></div>')
        }
      })
    })
  }

  #afterClick (node) {
    this.element.dispatchEvent(new CustomEvent('clicked', {
      detail: {
        node: node,
        data: { ...node.dataset }
      }, bubbles: true
    }))
  }
}
