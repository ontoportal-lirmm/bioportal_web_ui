import { Controller } from '@hotwired/stimulus'
import { getYasgui } from '../mixins/useYasgui'

export default class extends Controller {
  static values = {
    proxy: String,
    apikey: String,
    graph: String,
    sampleQueries: Array
  }

  connect() {
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

    this.#addExampleTabs()

    this.#setupSaveButton()

  }

  #proxyUrl() {
    return `${this.proxyValue}?default-graph-uri=${this.graphValue}&apikey=${this.apikeyValue}`
  }

  #addExampleTabs() {
    const defaultQuery = `# Add a description of your sample Query here

PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT * WHERE {
  ?sub ?pred ?obj .
} LIMIT 10`;

    setTimeout(() => {
      const queries = this.sampleQueriesValue;
      this.yasgui.getTab().close()
      if (queries.length === 0) {
        const tab = this.yasgui.addTab(true, { name: 'Sample query' }, { atIndex: 0 });
        tab.setQuery(defaultQuery);
      } else {
        for (let i = queries.length - 1; i >= 0; i--) {
          const tab = this.yasgui.addTab(true, { name: `Sample query ${i + 1}` }, { atIndex: 0 });
          tab.setQuery(queries[i]);
        }
      }
    }, 50);
  }

  #setupSaveButton() {
    const saveButton = document.getElementById('queries-save-button');
    if (saveButton) {
      saveButton.addEventListener('click', (e) => {
        this.#showMessage('Queries saved successfully', 'success');
        e.preventDefault();
        this.#saveCurrentQuery();
      });
    }
  }

  #saveCurrentQuery() {



    const tabElements = document.querySelectorAll('.edit_sparql_container [role="tab"]');
    const queries = [];
    tabElements.forEach(tabElement => {
      console.log('tabElement.id :', tabElement.id);
      const tab = this.yasgui.getTab(`${tabElement.id.split('-')[1]}`);
      query = tab.getQuery();
      if (query) {
        queries.push(query);
      }
    })
    if (queries.length > 0) {
      const ontologyId = this.#extractOntologyId();
      this.#sendSaveRequest(queries, ontologyId);
    }
  }



  #extractOntologyId() {
    const graph = this.graphValue;
    if (graph) {
      const match = graph.match(/\/ontologies\/([^\/]+)\/submissions\/([^\/]+)/);
      if (match) {
        return `/ontologies/${match[1]}/submissions/${match[2]}`;
      }
    }
    return null;
  }

  #sendSaveRequest(queries, ontologyId) {
    console.log('queryKey :', queries);

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    const formData = new FormData();
    formData.append('_method', 'patch');

    const queryKey = ontologyId ? 'ontology[sampleQueries][]' : 'config[sampleQueries][]';
    if (Array.isArray(queries)) {
      queries.forEach(query => {
        formData.append(queryKey, query);
      });
    } else {
      formData.append(queryKey, queries);
    }

    const endpoint = ontologyId ? `${ontologyId}` : '/admin/catalog_configuration'
    const graph = this.graphValue;

    const match = graph.match(/\/ontologies\/([^\/]+)\/submissions\/([^\/]+)/);

    if (ontologyId) {
      formData.append('ontology_id', match[1]);
    }

    fetch(endpoint, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken
      },
      body: formData
    })
      .then(response => {
        if (response.ok) {
          console.log('Queries saved successfully');
        } else {
          console.error('Failed to save queries');
        }
      })
      .catch(error => {
        console.error('Error saving queries:', error);
      });
  }


  #showMessage(message, type) {
    const notificationContainer = document.querySelector('.sparql-notifications');
    const messageDiv = document.createElement('div');
    messageDiv.textContent = message;
    messageDiv.style.padding = '10px 20px';
    messageDiv.style.borderRadius = '4px';
    messageDiv.style.backgroundColor = type === 'success' ? '#d4edda' : '#f8d7da';
    messageDiv.style.color = type === 'success' ? '#155724' : '#721c24';
    messageDiv.style.border = type === 'success' ? '1px solid #c3e6cb' : '1px solid #f5c6cb';
    messageDiv.style.marginBottom = '10px'

    if (notificationContainer) {
      notificationContainer.appendChild(messageDiv);

      setTimeout(() => {
        if (notificationContainer.contains(messageDiv)) {
          notificationContainer.removeChild(messageDiv);
        }
      }, 3000);
    } else {
      messageDiv.style.position = 'fixed';
      messageDiv.style.top = '20px';
      messageDiv.style.right = '20px';
      messageDiv.style.zIndex = '1000';

      document.body.appendChild(messageDiv);

      setTimeout(() => {
        if (document.body.contains(messageDiv)) {
          document.body.removeChild(messageDiv);
        }
      }, 3000);
    }
  }
}