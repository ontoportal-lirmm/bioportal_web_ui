import { Controller } from '@hotwired/stimulus'
import * as d3 from 'd3';

export default class extends Controller {
  static values = {
    mappingsList: Object,
    zoomRatio: Number
  }
  static targets = ['frame', 'bubbles', 'submit']

  connect() {
    this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue, this.#normalization_ratio(this.mappingsListValue))
    this.#center_scroll(this.frameTarget)
  }
  submit(){
    this.submitTarget.click()
  }

  select_bubble(event){
    const acronym = event.currentTarget.getAttribute('data-acronym')
    let url = 'mappings/ontology_mappings/' + acronym
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
                circle.style.fill = mappings_list.includes(acronym) ? 'red' : 'var(--primary-color)'
            }
            debugger
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

  #draw_bubbles(mappingsList, zoomRatio, normalization_ratio){
    const data = this.#hash_to_list(mappingsList)
    const width = 600*zoomRatio;
    const height = 600*zoomRatio;
    const margin = 1;
    const logScaleFactor = 10;

    const pack = d3.pack()
      .size([width - margin, height - margin])
      .padding(3);

    const color = d3.scaleOrdinal(d3.schemeCategory10);

    const root = d3.hierarchy({ children: data })
      .sum(d => d.ontology_mappings/normalization_ratio + Math.log(d.ontology_mappings + 1) / logScaleFactor);

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
      .attr('data-acronym', d => d.data.ontology_name);

    const circle = node.append("circle")
      .attr("r", d => d.r)
      .style("fill", "var(--primary-color)");
    // force gravitationnel
    circle.append("title")
      .text(d => `${d.data.ontology_name}\n${d.value}`);

    // Display ontology names in 16px white
    const textOntology = node.append("text")
      .attr("dy", ".35em")
      .style("text-anchor", "middle")
      .style("font-size", "16px")
      .style("fill", "white")
      .style("font-weight", "600")
      .text(d => (d.r > d.data.ontology_name.length*5 && d.r > 20) ? d.data.ontology_name : "");

    // Display number of mappings in 12px white below ontology names
    const textMappings = node.append("text")
      .attr("dy", "1.5em")
      .style("text-anchor", "middle")
      .style("font-size", "12px")
      .style("fill", "white")
      .text(d => (d.r > d.data.ontology_name.length*5 && d.r > 20) ? d.data.ontology_mappings : "");

    // Display ontology names in tooltips on hover
    circle.on("mouseover", function (event, d) {
      d3.select(this).append("title")
        .text(`${d.data.ontology_name}\n${d.data.ontology_mappings}`);
    }).on("mouseout", function (event, d) {
      d3.select(this).select("title").remove();
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