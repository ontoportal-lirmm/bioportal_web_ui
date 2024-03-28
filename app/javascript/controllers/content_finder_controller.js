import { Controller } from '@hotwired/stimulus'
import * as jsonld from 'jsonld'
import hljs from 'highlight.js/lib/core'
import xml from 'highlight.js/lib/languages/xml'
import json from 'highlight.js/lib/languages/json'

export default class extends Controller {
  static targets = ["content"]
  static values = {
    format: String
  }
  connect() {
    switch (this.formatValue) {
      case 'json':
        hljs.registerLanguage('json', json)
        this.showJSON()
        break
      case 'xml':
        hljs.registerLanguage('xml', xml)
        this.showXML()
        break
      case 'ntriples':
        hljs.registerLanguage('ntriples', function (hljs) {
          var URL_PATTERN = /<[^>]+>/; // Regex pattern for matching URLs in angle brackets
          return {
            case_insensitive: true,
            contains: [
              {
                className: 'subject',
                begin: /^<[^>]+>/,
              },
              {
                className: 'predicate',
                begin: /<[^>]+>/,
              },
              {
                className: 'object',
                begin: /\s([^\s]+)\s\./,
              },
              hljs.COMMENT('^#', '$')
            ]
          };
        });
        this.showNTriples()
        break
      case 'turtle':
        hljs.registerLanguage('turtle', function (hljs) {
          var URL_PATTERN = /(?:<[^>]*>)|(?:https?:\/\/[^\s]+)/;

          return {
            case_insensitive: true,
            contains: [
              {
                className: 'custom-prefixes',
                begin: '@prefix',
                relevance: 10
              },
              {
                className: 'meta',
                begin: /@base/,
                end: /[\r\n]|$/,
                relevance: 10
              },
              {
                className: 'variable',
                begin: /\?[\w\d]+/
              },
              {
                className: 'custom-symbol',
                begin: /@?[A-Za-z_][A-Za-z0-9_]*(?= *:)/,
                relevance: 10
              },
              {
                className: 'custom-concepts',
                begin: /:\s*(\w+)/,
                relevance: 10
              },
              {
                className: 'string',
                begin: URL_PATTERN
              }
            ]
          };
        });
        this.showTURTLE()
        break
    }
  }

  showJSON() {
    this.contentTarget.innerHTML = hljs.highlight(JSON.stringify(JSON.parse(this.contentTarget.textContent), null, "  "), { language: 'json' }).value
  }

  showXML() {
    this.contentTarget.innerHTML = hljs.highlight(this.contentTarget.textContent, { language: 'xml' }).value
  }

  showNTriples() {
    this.contentTarget.innerHTML = hljs.highlight(this.contentTarget.textContent, { language: 'ntriples' }).value
  }

  showTURTLE() {
    this.contentTarget.innerHTML = hljs.highlight(this.contentTarget.textContent, { language: 'turtle' }).value
  }
}
