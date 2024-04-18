import { Controller } from '@hotwired/stimulus'
import * as d3 from 'd3';

export default class extends Controller {
  static values = {
    mappingsList: Object,
    zoomRatio: Number,
    type: String,
    acronym: String,
    apiUrl: String
  }
  static targets = ['frame', 'bubbles', 'submit', 'modal', 'selector', 'ontologies', 'loader']

  connect() {
    this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue, this.#normalization_ratio(this.mappingsListValue))
    this.#center_scroll(this.frameTarget)
    if(this.typeValue == 'partial'){
      this.typeValue = 'disable'
      let acronym = this.acronymValue
      let bubbles = this.bubblesTarget 
      setTimeout(function() {
        const currentBubble = bubbles.querySelector(`[data-acronym="${acronym}"]`)
        let clickEvent = new MouseEvent("click", {
          bubbles: true,
          cancelable: true,
          view: window
        });
        currentBubble.dispatchEvent(clickEvent)
      }, 100); 
    }
  }
  filter_ontologies(){
    const selectOptions = this.ontologiesTarget.querySelector('select').selectedOptions
    if (selectOptions.length == 0){
      this.bubblesTarget.innerHTML = ''
      this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue, this.#normalization_ratio(this.mappingsListValue))
      this.#center_scroll(this.frameTarget)
      return
    }
    let acronyms = []
    for(let i=0; i<selectOptions.length; i++){
      acronyms.push(selectOptions[i].value)
    }
    const filteredList = Object.fromEntries(
      Object.entries(this.mappingsListValue).filter(([key]) => acronyms.includes(key))
    );
    this.bubblesTarget.innerHTML = ''
    this.#draw_bubbles(filteredList, this.zoomRatioValue, this.#normalization_ratio(filteredList))
    this.#center_scroll(this.frameTarget)
  }
  submit(event){
    if (event.currentTarget.querySelector('.item') == null){
      return
    }
    this.submitTarget.click()
    const selectValue = event.currentTarget.querySelector('select').value
    const selectAcronym = this.#get_acronym(selectValue)
    const bubblesContainer = document.getElementById('mappings-bubbles-view')
    const selected_bubble = bubblesContainer.querySelector('[data-selected="true"]')
    const currentBubble = bubblesContainer.querySelector(`[data-acronym="${selectAcronym}"]`)
    if (selected_bubble && selected_bubble.dataset.acronym === selectAcronym) {
      console.log('entered here')
      return;
    }
    let clickEvent = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      view: window
    });
    if(currentBubble.getAttribute('data-enabled') == 'false' || currentBubble.getAttribute('data-highlighted') == 'true'){
      selected_bubble.dispatchEvent(clickEvent)
    }
    currentBubble.dispatchEvent(clickEvent);
  }
  select_bubble(event){
    this.#loading_animation()
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
      const modal_link =  `/mappings/show_mappings?data%5Bshow_modal_size_value%5D=modal-xl&amp;data%5Bshow_modal_title_value%5D=bilel&amp;id=${acronym}&amp;target=${encodeURIComponent(this.apiUrlValue)}ontologies%2F${target_acronym}`
      this.modalTarget.querySelector('a').href = modal_link
      this.modalTarget.querySelector('a').click()
      this.#loading_animation()
      return
    }
    if(selected_bubble.getAttribute('data-enabled') == 'false'){
      this.#loading_animation()
      return
    }
    if(selected_bubble.getAttribute('data-selected') == 'true'){
        if (this.typeValue == 'disable'){
          this.#loading_animation()
          return
        }
        selected_bubble.setAttribute('data-selected', 'false')
        selected_circle.style.fill = 'var(--primary-color)'
        for(let i = 0; i<leafs.length; i++){
            const circle = leafs[i].querySelector('circle')
            circle.style.fill = 'var(--primary-color)'
            circle.style.opacity = '1'
            leafs[i].setAttribute('data-enabled', 'true')
            leafs[i].setAttribute('data-highlighted', 'false')
        }
        this.#loading_animation()
        return
    }
    selected_bubble.setAttribute('data-selected', 'true')
    if (this.typeValue != 'disable'){
      this.#init_select(selected_bubble.getAttribute('data-acronym'))
    } else {
      url = '../'+url
    }
    fetch(url)
        .then(response => {
            if (!response.ok) {
            throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            let mappings_list = []
            for(let i=0; i<data.length; i++){
                let list_item = {acronym: data[i]['target_ontology']['acronym'], count: data[i]['count']}
                mappings_list.push(list_item)
            }
            const bubblesContainer = document.getElementById('mappings-bubbles-view')
            const leafs = bubblesContainer.querySelectorAll('.leaf')
            const max_mappings_count = mappings_list.reduce((max, item) => Math.max(max, item.count), -Infinity);
            for(let i=0; i<leafs.length; i++){
                const circle = leafs[i].querySelector('circle')
                const acronym = leafs[i].getAttribute('data-acronym')
                if(mappings_list.some(item => item.acronym === acronym)){
                  leafs[i].setAttribute('data-highlighted', 'true')
                  circle.style.fill = 'var(--primary-color)'
                  const elem = mappings_list.find(item => item.acronym === acronym);
                  const opacity = (elem["count"] / max_mappings_count + Math.log( elem["count"] + 1)) / 10 + 0.3
                  circle.style.opacity = `${opacity}`
                } else {
                  leafs[i].setAttribute('data-enabled', 'false')
                  circle.style.fill = 'var(--light-color)'
                }
            }
            const selected_leaf = bubblesContainer.querySelector('[data-selected="true"]')
            selected_leaf.setAttribute('data-enabled', 'true')
            const selected_circle = selected_leaf.querySelector('circle')
            selected_circle.style.fill = 'var(--secondary-color)'
            this.#loading_animation()
        })
        .catch(error => {
            // Handle errors here
            console.error('There was a problem with the fetch operation:', error);
        });
  }

  zoomIn(){
    this.zoomRatioValue++
    this.bubblesTarget.innerHTML = ''
    this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue, this.#normalization_ratio(this.mappingsListValue))
    this.#center_scroll(this.frameTarget)
  }
  zoomOut(){
    if (this.zoomRatioValue>1){
      this.zoomRatioValue--
      this.bubblesTarget.innerHTML = ''
      this.#draw_bubbles(this.mappingsListValue, this.zoomRatioValue, this.#normalization_ratio(this.mappingsListValue))
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
    let parts = url.split('/');
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
  #init_select(acronym){
    let input = this.selectorTarget.querySelector('input')
    input.value = acronym
    input.dispatchEvent(new Event('input', { bubbles: true }));
    for(let i = 0; i<this.selectorTarget.querySelectorAll('.option').length; i++){
      const selectValue = this.selectorTarget.querySelectorAll('.option')[i]
      const selectAcronym = this.#get_acronym(selectValue.getAttribute('data-value'))
      if(selectAcronym == acronym){
        selectValue.click()
      }
    }
  }
  #get_acronym(selectValue){
    acronym = selectValue.split('-')
    acronym.shift()
    return acronym.join('-').split('(')[0].replace(/\s/g, '')
  }
  #loading_animation(){
    this.loaderTarget.classList.toggle('d-none')
    this.bubblesTarget.classList.toggle('d-none')
  }
}