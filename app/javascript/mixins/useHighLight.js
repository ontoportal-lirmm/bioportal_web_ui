import hljs from 'highlight.js/lib/core'
import xml from 'highlight.js/lib/languages/xml'
import json from 'highlight.js/lib/languages/json'

class HighLighter {
  constructor (highlighter, format) {
    switch (format) {
      case 'xml':
        highlighter.registerLanguage('xml', xml)
        break
      case 'json':
        highlighter.registerLanguage('json', json)
        break
      case 'triples':
      case 'ntriples':  
        highlighter.registerLanguage('ntriples', function (hljs) {
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
          }
        })
        break
      case 'turtle':
        highlighter.registerLanguage('turtle', function (hljs) {
          let URL_PATTERN = /(?:<[^>]*>)|(?:https?:\/\/[^\s]+)/

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
          }
        })
        break
    }
    this.highlighter = highlighter
  }

  highlight (text, format) {
    return this.highlighter.highlight(text, { language: format }).value
  }
}

export function useHighLighter (format) {
  return new HighLighter(hljs, format)
}