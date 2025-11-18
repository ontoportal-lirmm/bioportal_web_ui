import { Controller } from '@hotwired/stimulus'
import { getYasgui } from '../mixins/useYasgui'

// Connects to data-controller="sparql"
export default class extends Controller {
  static values = {
    proxy: String,
    apikey: String,
    graph: String,
  }
  
  connect () {
    localStorage.removeItem('yagui__config');
    this.yasgui = getYasgui(this.element,
      {
        copyEndpointOnNewTab: true,
        requestConfig: {
          endpoint: this.#proxyUrl(), 
          acceptHeaderGraph: false,
          acceptHeaderUpdate: false,
        }
      })

    // Add example query tabs
    this.#addExampleTabs()
  }

  #proxyUrl(){
    return `${this.proxyValue}?default-graph-uri=${this.graphValue}&apikey=${this.apikeyValue}`
  }

  #addExampleTabs() {
    // Wait a bit for YASGUI to fully initialize
    setTimeout(() => {
      const queries = [
        {
          name: "Discover Classes",
          query: `SELECT DISTINCT ?class (COUNT(?instance) AS ?instanceCount)
WHERE {
  ?instance a ?class .
}
GROUP BY ?class
ORDER BY DESC(?instanceCount) LIMIT 10`
        },
        {
          name: "Datatype Properties", 
          query: `SELECT DISTINCT ?property ?datatype
           (COUNT(*) AS ?usageCount)
WHERE {
  ?subject ?property ?object .
  FILTER isLiteral(?object)
  BIND(datatype(?object) AS ?datatype)
}
GROUP BY ?property ?datatype
ORDER BY DESC(?usageCount) LIMIT 50`
        },
        {
          name: "Explore All Triples",
          query: `SELECT ?subject ?predicate ?object
WHERE {
  ?subject ?predicate ?object .
} LIMIT 50`
        }
      ];
      this.yasgui.getTab().close()
      for (let i = 0; i < queries.length; i++) {
        const tab = this.yasgui.addTab(true, { name: queries[i].name}, {atIndex: 0});
        tab.setQuery(queries[i].query);
      }

    }, 50); 
  }
}