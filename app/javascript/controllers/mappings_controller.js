import { Controller } from '@hotwired/stimulus'
import * as d3 from 'd3';

export default class extends Controller {
  static values = {
    mappingsList: Object,
    zoomRatio: Number
  }
  static targets = ['frame', 'bubbles', 'submit', 'modal']

  connect() {
    this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue, this.#normalization_ratio(this.mappingsListValue))
    this.#center_scroll(this.frameTarget)
  }
  submit(){
    this.submitTarget.click()
  }

  select_bubble(event){
    const selected_bubble = event.currentTarget
    const selected_circle = selected_bubble.querySelector('circle')
    const bubblesContainer = document.getElementById('mappings-bubbles-view')
    const leafs = bubblesContainer.querySelectorAll('.leaf')
    const acronym = selected_bubble.getAttribute('data-acronym')
    let url = 'mappings/ontology_mappings/' + acronym
    if(selected_bubble.getAttribute('data-highlighted') == 'true'){
      const selected_leaf = bubblesContainer.querySelector('[data-selected="true"]')
      const acronym = selected_leaf.getAttribute('data-acronym')
      const target_acronym = selected_bubble.getAttribute('data-acronym')
      debugger
      const modal_link = `/mappings/show_mappings?data%5Bshow_modal_size_value%5D=modal-xl&amp;data%5Bshow_modal_title_value%5D=bilel&amp;id=${acronym}&amp;target=https%3A%2F%2Fdata.agroportal.lirmm.fr%2Fontologies%2F${target_acronym}`
      this.modalTarget.querySelector('a').href = modal_link
      this.modalTarget.querySelector('a').click()
      return
    }
    if(selected_bubble.getAttribute('data-enabled') == 'false'){
      return
    }
    if(selected_bubble.getAttribute('data-selected') == 'true'){
        selected_bubble.setAttribute('data-selected', 'false')
        selected_circle.style.fill = 'var(--primary-color)'
        for(let i = 0; i<leafs.length; i++){
            const circle = leafs[i].querySelector('circle')
            circle.style.fill = 'var(--primary-color)'
            leafs[i].setAttribute('data-enabled', 'true')
            leafs[i].setAttribute('data-highlighted', 'false')
        }
        return
    }
    selected_bubble.setAttribute('data-selected', 'true')
    fetch(url)
        .then(response => {
            if (!response.ok) {
            throw new Error('Network response was not ok');
            }
            return response.json(); // assuming response is JSON
        })
        .then(data => {
            let mappings_list = []
            for(let i=0; i<data.length; i++){
                mappings_list.push(data[i]['target_ontology']['acronym'])
            }
            const bubblesContainer = document.getElementById('mappings-bubbles-view')
            const leafs = bubblesContainer.querySelectorAll('.leaf')
            for(let i=0; i<leafs.length; i++){
                const circle = leafs[i].querySelector('circle')
                const acronym = leafs[i].getAttribute('data-acronym')
                circle.style.fill = mappings_list.includes(acronym) ? 'var(--primary-color)' : 'var(--light-color)'
                if(mappings_list.includes(acronym)){
                  leafs[i].setAttribute('data-highlighted', 'true')
                } else {
                  leafs[i].setAttribute('data-enabled', 'false')
                }
            }
            const selected_leaf = bubblesContainer.querySelector('[data-selected="true"]')
            selected_leaf.setAttribute('data-enabled', 'true')
            const selected_circle = selected_leaf.querySelector('circle')
            selected_circle.style.fill = 'var(--secondary-color)'
        })
        .catch(error => {
            // Handle errors here
            console.error('There was a problem with the fetch operation:', error);
        });
  }

  zoomIn(){
    this.zoomRatioValue++
    this.bubblesTarget.innerHTML = ''
    this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue)
    this.#center_scroll(this.frameTarget)
  }
  zoomOut(){
    if (this.zoomRatioValue>1){
      this.zoomRatioValue--
      this.bubblesTarget.innerHTML = ''
      this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue)
      this.#center_scroll(this.frameTarget)
    }
  }

  #draw_bubbles(mappingsList, zoomRatio, normalization_ratio) {
    const data = this.#hash_to_list(mappingsList);
    const width = 600 * zoomRatio;
    const height = 600 * zoomRatio;
    const margin = 1;
    const logScaleFactor = 10;

    const pack = d3.pack()
        .size([width - margin, height - margin])
        .padding(3);

    const color = d3.scaleOrdinal(d3.schemeCategory10);

    const root = d3.hierarchy({ children: data })
        .sum(d => d.ontology_mappings / normalization_ratio + Math.log(d.ontology_mappings + 1) / logScaleFactor);

    const svg = d3.select("#mappings-bubbles-view")
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", `translate(${margin}, ${margin})`);

    const node = svg.selectAll(".node")
        .data(pack(root).descendants().slice(1)) // Exclude the root node
        .enter().append("g")
        .attr("class", d => d.children ? "node mappings-bubble" : "leaf mappings-bubble")
        .attr("transform", d => `translate(${d.x},${d.y})`)
        .attr('data-action', 'click->mappings#select_bubble')
        .attr('data-acronym', d => d.data.ontology_name)
        .attr('data-enabled', d => 'true');

    const circle = node.append("circle")
        .attr("r", d => d.r)
        .style("fill", "var(--primary-color)");

    // Display ontology names in 16px white
    const textOntology = node.append("text")
        .attr("dy", ".35em")
        .style("text-anchor", "middle")
        .style("font-size", "16px")
        .style("fill", "white")
        .style("font-weight", "600")
        .text(d => (d.r > d.data.ontology_name.length * 5 && d.r > 20) ? d.data.ontology_name : "");

    // Display number of mappings in 12px white below ontology names
    const textMappings = node.append("text")
        .attr("dy", "1.5em")
        .style("text-anchor", "middle")
        .style("font-size", "12px")
        .style("fill", "white")
        .text(d => (d.r > d.data.ontology_name.length * 5 && d.r > 20) ? d.data.ontology_mappings : "");

    // Display ontology names in bubble tooltips on hover
    circle.on("mouseover", function (event, d) {
      if (!(d.r > d.data.ontology_name.length * 5 && d.r > 20)) {
          // Remove existing tooltip
          d3.selectAll(".bubble-tooltip").remove();

          // Calculate tooltip position based on mouse coordinates
          const tooltip = d3.select("body")
              .append("div")
              .attr("class", "bubble-tooltip")
              .style("left", `${event.pageX + 10}px`) // Adjust position relative to mouse pointer
              .style("top", `${event.pageY + 10}px`) // Adjust position relative to mouse pointer
              .html(`<strong>${d.data.ontology_name}</strong><br>${d.data.ontology_mappings}`);
      }
    }).on("mouseout", function (event, d) {
        // Remove tooltip on mouseout
        d3.selectAll(".bubble-tooltip").remove();
    });


    this.svg = svg;
  }



  #hash_to_list(data){
    return Object.keys(data).map(key => ({
      ontology_name: this.#getLastPartOfUrl(key),
      ontology_mappings: data[key],
    }));
  }
  #getLastPartOfUrl(url) {
    var parts = url.split('/');
    return parts[parts.length - 1];
  }

  #center_scroll(frame){
    frame.scrollTop = frame.scrollHeight / 2 - frame.clientHeight / 2;
    frame.scrollLeft = frame.scrollWidth / 2 - frame.clientWidth / 2;
  }

  #normalization_ratio(ontologies_hash){
    let maxValue = -Infinity
    for (const value of Object.values(ontologies_hash)) {
      maxValue = (maxValue < value) ? value : maxValue
    }
    let normalization_ratio = 1
    while((maxValue / normalization_ratio)>10){
      normalization_ratio *= 10
    }
    return normalization_ratio
  }
}