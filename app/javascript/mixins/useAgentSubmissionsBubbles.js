import * as d3 from 'd3'

class BubbleData {
  constructor(ontology_name, ontology_bubble_size, role) {
    this.ontology_name = ontology_name;
    this.ontology_bubble_size = ontology_bubble_size;
    this.role = role;
  }
}

/**
 * Draws bubbles using D3.js based on the provided data.
 * @param {Array<BubbleData>} data - The array of BubbleData objects containing ontology names.
 * @param {number} width - The width of the SVG container.
 * @param {number} height - The height of the SVG container.
 * @param {number} margin - The margin for the SVG container.
 * @param {HTMLElement} bubblesTarget - The target HTML element to append the SVG container to.
 * @param {number} normalization_ratio - The normalization ratio for bubble size calculation.
 * @param {number} logScaleFactor - The logarithmic scale factor for bubble size calculation.
 */
export function useAgentSubmissionsDrawBubbles(data, width, height, margin, bubblesTarget, normalization_ratio, logScaleFactor) {
  // Define pack layout
  const pack = d3.pack()
    .size([width - margin, height - margin])
    .padding(3);

  // Create hierarchy and sum for bubble sizes
  const root = d3.hierarchy({ children: data })
    .sum(d => calculateBubbleSize(d));

  // Create SVG container
  const svg = d3.select(`#${bubblesTarget.id}`)
    .append('svg')
    .attr('width', width)
    .attr('height', height)
    .append('g')
    .attr('transform', `translate(${margin}, ${margin})`);

  // Create nodes and bind data
  const node = svg.selectAll('.node')
    .data(pack(root).descendants().slice(1)) // Exclude the root node
    .enter().append('g')
    .attr('class', d => d.children ? 'node submissions-bubble' : 'leaf submissions-bubble')
    .attr('transform', d => `translate(${d.x},${d.y})`)
    .attr('data-action', 'click->agent-bubbles-submissions#selectBubble')
    .attr('data-acronym', d => d.data.ontology_name)
    .attr('data-enabled', d => 'true');

  // Create circles with hover effect
  const circle = node.append('circle')
    .attr('r', d => d.r)
    .style('fill', 'var(--primary-color)')
    .style('transition', 'all 0.3s ease') // Smooth transition for hover effects
    .on('mouseover', function(event, d) {
      // Increase size slightly
      d3.select(this)
        .style('transform', 'scale(1.02)')
        .style('filter', 'brightness(1.2)')
        .style('cursor', 'pointer');
      
      // Show tooltip
      showTooltip(event, d);
    })
    .on('mouseout', function() {
      // Reset to original state
      d3.select(this)
        .style('transform', 'scale(1)')
        .style('filter', 'brightness(1)')
        .style('cursor', 'default');
      
      // Hide tooltip
      hideTooltip();
    });

  // Display ontology names 
  const textOntology = node.append('text')
    .attr('dy', '.35em')
    .style('text-anchor', 'middle')
    .style('font-size', '16px')
    .style('fill', 'white')
    .style('font-weight', '600')
    .text(d => displayOntologyName(d));

    const textRole = node.append('text')
    .attr('dy', '1.8em')
    .style('text-anchor', 'middle')
    .style('font-size', '12px')
    .style('fill', 'white')
    .style('font-weight', '500')
    .text(d => displagentRole(d)
  );
  // Function to calculate bubble size
  function calculateBubbleSize(d) {
    return d.ontology_bubble_size / normalization_ratio + Math.log(d.ontology_bubble_size + 1) / logScaleFactor;
  }

  // Function to display ontology name
  function displayOntologyName(d) {
    return (d.r > d.data.ontology_name.length * 5 && d.r > 20) ? d.data.ontology_name : '';
  }
    // Function to display Agent Role
  function displagentRole(d) {
    return (d.r > d.data.ontology_name.length * 5 && d.r > 50) ? d.data.role : '';
  }

  // Tooltip functions
  function showTooltip(event, d) {
    // Remove any existing tooltips
    d3.select('body').selectAll('.bubble-tooltip').remove();

    // Create tooltip
    const tooltip = d3.select('body')
      .append('div')
      .attr('class', 'bubble-tooltip')
      .style('position', 'absolute')
      .style('background', 'rgba(0,0,0,0.8)')
      .style('color', 'white')
      .style('padding', '10px')
      .style('border-radius', '5px')
      .style('pointer-events', 'none')
      .style('left', `${event.pageX + 10}px`)
      .style('top', `${event.pageY + 10}px`)
      .html(`
        <strong>${d.data.ontology_name}</strong><br><span>${d.data.role}</span>
      `);
  }

  function hideTooltip() {
    d3.select('body').selectAll('.bubble-tooltip').remove();
  }
}