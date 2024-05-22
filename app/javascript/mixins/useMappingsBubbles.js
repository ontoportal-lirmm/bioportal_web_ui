import * as d3 from 'd3'

class BubbleData {
  constructor(ontology_name, ontology_mappings) {
    this.ontology_name = ontology_name;
    this.ontology_mappings = ontology_mappings;
  }
}

/**
 * Draws bubbles using D3.js based on the provided data.
 * @param {Array<BubbleData>} data - The array of BubbleData objects containing ontology names and mappings.
 * @param {number} width - The width of the SVG container.
 * @param {number} height - The height of the SVG container.
 * @param {number} margin - The margin for the SVG container.
 * @param {HTMLElement} bubblesTarget - The target HTML element to append the SVG container to.
 * @param {number} normalization_ratio - The normalization ratio for bubble size calculation.
 * @param {number} logScaleFactor - The logarithmic scale factor for bubble size calculation.
 */

export function useMappingsDrawBubbles(data, width, height, margin, bubblesTarget, normalization_ratio, logScaleFactor) {
  // Define pack layout
  const pack = d3.pack()
    .size([width - margin, height - margin])
    .padding(3);

  // Create hierarchy and sum for bubble sizes
  const root = d3.hierarchy({ children: data })
    .sum(d => calculateBubbleSize(d));

  // Create SVG container
  const svg =  d3.select(`#${bubblesTarget.id}`)
    .append('svg')
    .attr('width', width)
    .attr('height', height)
    .append('g')
    .attr('transform', `translate(${margin}, ${margin})`)

  // Create nodes and bind data
  const node = svg.selectAll('.node')
    .data(pack(root).descendants().slice(1)) // Exclude the root node
    .enter().append('g')
    .attr('class', d => d.children ? 'node mappings-bubble' : 'leaf mappings-bubble')
    .attr('transform', d => `translate(${d.x},${d.y})`)
    .attr('data-action', 'click->mappings#selectBubble')
    .attr('data-acronym', d => d.data.ontology_name)
    .attr('data-enabled', d => 'true');

  // Create circles
  const circle = node.append('circle')
    .attr('r', d => d.r)
    .style('fill', 'var(--primary-color)');

  // Display ontology names and mappings
  const textOntology = node.append('text')
    .attr('dy', '.35em')
    .style('text-anchor', 'middle')
    .style('font-size', '16px')
    .style('fill', 'white')
    .style('font-weight', '600')
    .text(d => displayOntologyName(d));

  const textMappings = node.append('text')
    .attr('dy', '1.5em')
    .style('text-anchor', 'middle')
    .style('font-size', '12px')
    .style('fill', 'white')
    .text(d => displayMappings(d));

  // Show tooltips on hover
  circle.on('mouseover', (event, d) => showTooltip(event, d))
    .on('mouseout', () => hideTooltip());

  // Function to calculate bubble size
  function calculateBubbleSize(d) {
    return d.ontology_mappings / normalization_ratio + Math.log(d.ontology_mappings + 1) / logScaleFactor;
  }

  // Function to display ontology name
  function displayOntologyName(d) {
    return (d.r > d.data.ontology_name.length * 5 && d.r > 20) ? d.data.ontology_name : '';
  }

  // Function to display mappings count
  function displayMappings(d) {
    return (d.r > d.data.ontology_name.length * 5 && d.r > 20) ? d.data.ontology_mappings : '';
  }

  // Function to show tooltip
  function showTooltip(event, d) {
    if (!(d.r > d.data.ontology_name.length * 5 && d.r > 20)) {
      // Remove existing tooltip
      d3.selectAll('.bubble-tooltip').remove();

      // Calculate tooltip position based on mouse coordinates
      const tooltip = d3.select('body')
        .append('div')
        .attr('class', 'bubble-tooltip')
        .style('left', `${event.pageX + 10}px`) // Adjust position relative to mouse pointer
        .style('top', `${event.pageY + 10}px`) // Adjust position relative to mouse pointer
        .html(`<strong>${d.data.ontology_name}</strong><br>${d.data.ontology_mappings}`);
    }
  }

  // Function to hide tooltip
  function hideTooltip() {
    // Remove tooltip on mouseout
    d3.selectAll('.bubble-tooltip').remove();
  }
}
