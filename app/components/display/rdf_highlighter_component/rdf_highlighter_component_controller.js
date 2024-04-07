import { Controller } from '@hotwired/stimulus'
import * as jsonld from 'jsonld'
import { useHighLighter } from '../../../javascript/mixins/useHighLight'

// Connects to data-controller="rdf-highlighter"
export default class extends Controller {

  static targets = ['content', 'loader']
  static values = {
    metadata: Object,
    context: Object,
    namespaces: Object,
    format: { type: String, default: 'xml' }
  }

  connect () {
    this.formatedData = this.#formatData()
    this.highlighter = useHighLighter(this.formatValue)

    switch (this.formatValue) {
      case 'xml':
        this.showXML()
        break
      case 'json':
        this.showJSONLD()
        break
      case 'triples':
        this.showNTriples()
        break
      case 'ntriples':
        this.showNTriples()
        break
      case 'turtle':
        this.showTURTLE()
        break
    }
  }

  download () {
    switch (this.formatValue) {
      case 'xml':
        this.downloadXML()
        break
      case 'json':
        this.downloadJsonLd()
        break
      case 'triples':
        this.downloadNQuads()
        break
      case 'csv':
        this.downloadCSV()
    }
  }

  showNTriples () {
    if (!this.hasMetadataValue) {
      this.contentTarget.innerHTML = this.highlighter.highlight(this.contentTarget.textContent, 'ntriples')
    } else {
      this.#toggleLoader()
      this.#toNTriples(this.formatedData).then((nquads) => {
        this.contentTarget.innerHTML = this.highlighter.highlight(nquads, 'ntriples')
        this.#toggleLoader()
      })
    }
  }

  showXML () {
    if (!this.hasMetadataValue) {
      this.contentTarget.innerHTML = this.highlighter.highlight(this.contentTarget.textContent, 'xml')
    } else {
      this.#toggleLoader()
      const xml = this.#toXML(this.formatedData, this.contextValue)
      this.contentTarget.innerHTML = this.highlighter.highlight(xml, 'xml')
      this.#toggleLoader()
    }
  }

  showJSONLD () {
    if (!this.hasMetadataValue) {
      this.contentTarget.innerHTML = this.highlighter.highlight(JSON.stringify(JSON.parse(this.contentTarget.textContent), null, '  '), 'json')
    } else {
      this.#toggleLoader()
      this.#toJSONLD().then((jsonld) => {
        this.contentTarget.innerHTML = this.highlighter.highlight(JSON.stringify(jsonld, null, '  '), 'json')
        this.#toggleLoader()
      })
    }
  }

  showTURTLE () {
    this.contentTarget.innerHTML = this.highlighter.highlight(this.contentTarget.textContent, 'turtle')
  }

  #toggleLoader () {
    this.loaderTarget.classList.toggle('d-none')
  }

  downloadNQuads () {
    this.#toNTriples(this.formatedData).then((nquads) => {
      this.#generateDownloadFile(nquads, 'nt')
    })
  }

  downloadJsonLd () {
    this.#toJSONLD().then((jsonld) => {
      this.#generateDownloadFile(JSON.stringify(jsonld, null, '  '), 'nt')
    })
  }

  downloadXML () {
    this.#generateDownloadFile(this.#toXML(this.formatedData, this.submissionValue['context']), 'rdf')
  }

  downloadCSV () {
    this.#generateDownloadFile(this.#toCSV(), 'csv')
  }

  #formatData () {
    const jsonldObject = {}

    const subJson = this.metadataValue
    const ontJson = subJson
    const fullContext = this.contextValue

    // Remove links, context and metrics from json
    delete subJson['links']
    delete subJson['context']
    delete subJson['metrics']

    // Add ontology properties to context and subJson
    subJson['viewOf'] = ontJson['viewOf']
    subJson['group'] = ontJson['group']
    subJson['hasDomain'] = ontJson['hasDomain']

    // Don't add null value and empty arrays
    for (const [attr, value] of Object.entries(subJson)) {
      if (value === null || value === undefined || (Array.isArray(value) && value.length === 0)) {
        continue
      }

      if (fullContext.hasOwnProperty(attr)) {
        jsonldObject[fullContext[attr]] = value
      }
    }

    // Add id and type
    if (subJson['URI'] !== null) {
      jsonldObject['@id'] = subJson['URI']
    } else {
      jsonldObject['@id'] = ontJson['id']
    }
    jsonldObject['@type'] = 'http://www.w3.org/2002/07/owl#Ontology'

    return jsonldObject
  }

  #toNTriples (data) {
    return jsonld.toRDF(data, { format: 'application/n-quads' })
  }

  #toCSV () {
    return Object.entries(this.formatedData).map(([key, value]) => `${key},${value}`).join('\r\n')
  }

  #toJSONLD () {
    return jsonld.compact(this.formatedData, this.contextValue)
  }

  #toXML () {
    const data = this.formatedData
    const resolveNamespace = this.namespacesValue
    let namespaces = {}
    let xmlString = ''

    delete data['@id']
    delete data['@type']

    for (let prop in data) {
      const attr_uri = prop

      // Replace the full URI by namespace:attr
      for (const ns in resolveNamespace) {
        if (prop.startsWith(resolveNamespace[ns])) {
          namespaces[ns] = resolveNamespace[ns]
          prop = prop.replace(resolveNamespace[ns], ns + ':')
          break
        }
      }

      // Check if the value is an URI using simple regex
      let prop_values = Array.isArray(data[attr_uri]) ? data[attr_uri] : [data[attr_uri]]

      prop_values.forEach(prop_value => {
        const isUri = prop_value.toString().match(/https?:\/\//) && prop_value.toString().indexOf(' ') === -1
        const value = isUri ? '' : `${prop_value} <${prop}/> `
        xmlString = xmlString.concat(`    <${prop}${isUri ? ` rdf:resource="${prop_value}"/>` : '>'} ${value}\n`)
      })
    }

    let prefix = Object.entries(namespaces).map(([k, v]) => `xmlns:${k}="${v}"`).join(' ')
    return `<rdf:RDF ${prefix}>\n<rdf:Description rdf:about="${data['URI'] || data['@id']}">\n    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Ontology"/>${xmlString}</rdf:Description>\n</rdf:RDF>`
  }

  /**
   * Generate the file with metadata to be downloaded, given the file content
   * @param content
   * @param fileExtension
   */
  #generateDownloadFile (content, fileExtension) {
    var element = document.createElement('a')
    // TODO: change MIME type?
    element.setAttribute('href', 'data:application/rdf+json;charset=utf-8,' + encodeURIComponent(content))
    element.setAttribute('download', jQuery(document).data().bp.ontology.acronym + '_metadata.' + fileExtension)

    element.style.display = 'none'
    document.body.appendChild(element)
    element.click()
    document.body.removeChild(element)
  }
}


