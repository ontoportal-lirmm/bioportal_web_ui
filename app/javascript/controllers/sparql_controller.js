import { Controller } from '@hotwired/stimulus'
import { getYasgui } from '../mixins/useYasgui'

// Connects to data-controller="sparql"
export default class extends Controller {
  static  values = {
    proxy: String,
    graph: String,
  }
  connect () {
    localStorage.removeItem('yagui__config');
    this.yasgui = getYasgui(this.element,
      {
        corsProxy: this.proxyValue,
        copyEndpointOnNewTab: true,
        requestConfig: {
          endpoint: this.proxyValue,
          acceptHeaderGraph: false,
          acceptHeaderUpdate: false,
          namedGraphs: [this.graphValue],
        }
      })

  }
}
