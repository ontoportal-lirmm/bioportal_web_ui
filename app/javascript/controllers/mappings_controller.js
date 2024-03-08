import { Controller } from '@hotwired/stimulus'
import * as d3 from 'd3';

export default class extends Controller {
  static values = {
    mappingsList: Object,
    zoomRatio: Number
  }
  static targets = ['frame', 'bubbles', 'submit']

  connect() {
    this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue)
    this.#center_scroll(this.frameTarget)
  }
  submit(){
    this.submitTarget.click()
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

  #draw_bubbles(mappingsList, zoomRatio){
    const data = this.#hash_to_list(mappingsList)
    const width = 600*zoomRatio;
    const height = 600*zoomRatio;
    const margin = 1;

    const pack = d3.pack()
      .size([width - margin, height - margin])
      .padding(3);

    const color = d3.scaleOrdinal(d3.schemeCategory10);

    const root = d3.hierarchy({ children: data })
      .sum(d => d.ontology_mappings);

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
      .attr("transform", d => `translate(${d.x},${d.y})`);

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
        .text(`${d.data.ontology_name}\n${d.value}`);
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
}