import { Controller } from '@hotwired/stimulus'
import * as d3 from 'd3';

export default class extends Controller {
  connect() {
    const data = [
        { ontology_name: 'ont1', ontology_mappings: 56 },
        { ontology_name: 'ont2', ontology_mappings: 33 },
        { ontology_name: 'ont3', ontology_mappings: 78 },
        { ontology_name: 'ont4', ontology_mappings: 21 },
        { ontology_name: 'ont5', ontology_mappings: 45 },
        { ontology_name: 'ont6', ontology_mappings: 89 },
        { ontology_name: 'ont7', ontology_mappings: 12 },
        { ontology_name: 'ont8', ontology_mappings: 67 },
        { ontology_name: 'ont9', ontology_mappings: 53 },
        { ontology_name: 'ont10', ontology_mappings: 30 },
        { ontology_name: 'ont11', ontology_mappings: 88 },
        { ontology_name: 'ont12', ontology_mappings: 42 },
        { ontology_name: 'ont13', ontology_mappings: 65 },
        { ontology_name: 'ont14', ontology_mappings: 17 },
        { ontology_name: 'ont15', ontology_mappings: 74 },
        { ontology_name: 'ont16', ontology_mappings: 26 },
        { ontology_name: 'ont17', ontology_mappings: 60 },
        { ontology_name: 'ont18', ontology_mappings: 38 },
        { ontology_name: 'ont19', ontology_mappings: 81 },
        { ontology_name: 'ont20', ontology_mappings: 49 },
        { ontology_name: 'ont21', ontology_mappings: 93 },
        { ontology_name: 'ont22', ontology_mappings: 14 },
        { ontology_name: 'ont23', ontology_mappings: 70 },
        { ontology_name: 'ont24', ontology_mappings: 36 },
        { ontology_name: 'ont25', ontology_mappings: 79 },
        { ontology_name: 'ont26', ontology_mappings: 23 },
        { ontology_name: 'ont27', ontology_mappings: 55 },
        { ontology_name: 'ont28', ontology_mappings: 98 },
        { ontology_name: 'ont29', ontology_mappings: 10 },
        { ontology_name: 'ont30', ontology_mappings: 62 },
        { ontology_name: 'ont31', ontology_mappings: 32 },
        { ontology_name: 'ont32', ontology_mappings: 68 },
        { ontology_name: 'ont33', ontology_mappings: 41 },
        { ontology_name: 'ont34', ontology_mappings: 84 },
        { ontology_name: 'ont35', ontology_mappings: 19 },
        { ontology_name: 'ont36', ontology_mappings: 72 },
        { ontology_name: 'ont37', ontology_mappings: 28 },
        { ontology_name: 'ont38', ontology_mappings: 59 },
        { ontology_name: 'ont39', ontology_mappings: 95 },
        { ontology_name: 'ont40', ontology_mappings: 15 },
        { ontology_name: 'ont41', ontology_mappings: 76 },
        { ontology_name: 'ont42', ontology_mappings: 24 },
        { ontology_name: 'ont43', ontology_mappings: 57 },
        { ontology_name: 'ont44', ontology_mappings: 87 },
        { ontology_name: 'ont45', ontology_mappings: 11 },
        { ontology_name: 'ont46', ontology_mappings: 64 },
        { ontology_name: 'ont47', ontology_mappings: 33 },
        { ontology_name: 'ont48', ontology_mappings: 69 },
        { ontology_name: 'ont49', ontology_mappings: 37 },
        { ontology_name: 'ont50', ontology_mappings: 80 },
        { ontology_name: 'ont51', ontology_mappings: 54 },
        { ontology_name: 'ont52', ontology_mappings: 87 },
        { ontology_name: 'ont53', ontology_mappings: 18 },
        { ontology_name: 'ont54', ontology_mappings: 71 },
        { ontology_name: 'ont55', ontology_mappings: 29 },
        { ontology_name: 'ont56', ontology_mappings: 63 },
        { ontology_name: 'ont57', ontology_mappings: 99 },
        { ontology_name: 'ont58', ontology_mappings: 13 },
        { ontology_name: 'ont59', ontology_mappings: 66 },
        { ontology_name: 'ont60', ontology_mappings: 35 },
        { ontology_name: 'ont61', ontology_mappings: 73 },
        { ontology_name: 'ont62', ontology_mappings: 21 },
        { ontology_name: 'ont63', ontology_mappings: 58 },
        { ontology_name: 'ont64', ontology_mappings: 92 },
        { ontology_name: 'ont65', ontology_mappings: 16 },
        { ontology_name: 'ont66', ontology_mappings: 83 },
        { ontology_name: 'ont67', ontology_mappings: 47 },
        { ontology_name: 'ont68', ontology_mappings: 82 },
        { ontology_name: 'ont69', ontology_mappings: 31 },
        { ontology_name: 'ont70', ontology_mappings: 75 },
        { ontology_name: 'ont71', ontology_mappings: 27 },
        { ontology_name: 'ont72', ontology_mappings: 61 },
        { ontology_name: 'ont73', ontology_mappings: 90 },
        { ontology_name: 'ont74', ontology_mappings: 44 },
        { ontology_name: 'ont75', ontology_mappings: 86 },
        { ontology_name: 'ont76', ontology_mappings: 22 },
        { ontology_name: 'ont77', ontology_mappings: 53 },
        { ontology_name: 'ont78', ontology_mappings: 97 },
        { ontology_name: 'ont79', ontology_mappings: 9 },
        { ontology_name: 'ont80', ontology_mappings: 51 },
        { ontology_name: 'ont81', ontology_mappings: 34 },
        { ontology_name: 'ont82', ontology_mappings: 77 },
        { ontology_name: 'ont83', ontology_mappings: 25 },
        { ontology_name: 'ont84', ontology_mappings: 67 },
        { ontology_name: 'ont85', ontology_mappings: 94 },
        { ontology_name: 'ont86', ontology_mappings: 43 },
        { ontology_name: 'ont87', ontology_mappings: 72 },
        { ontology_name: 'ont88', ontology_mappings: 12 },
        { ontology_name: 'ont89', ontology_mappings: 50 },
        { ontology_name: 'ont90', ontology_mappings: 85 },
        { ontology_name: 'ont91', ontology_mappings: 40 },
        { ontology_name: 'ont92', ontology_mappings: 74 },
        { ontology_name: 'ont93', ontology_mappings: 26 },
        { ontology_name: 'ont94', ontology_mappings: 69 },
        { ontology_name: 'ont95', ontology_mappings: 98 },
        { ontology_name: 'ont96', ontology_mappings: 14 },
        { ontology_name: 'ont97', ontology_mappings: 56 },
        { ontology_name: 'ont98', ontology_mappings: 31 },
        { ontology_name: 'ont99', ontology_mappings: 63 },
        { ontology_name: 'ont100', ontology_mappings: 36 }
    ];

    const width = 600;
    const height = 600;
    const margin = 10;

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
      .attr("class", d => d.children ? "node" : "leaf")
      .attr("transform", d => `translate(${d.x},${d.y})`);

    const circle = node.append("circle")
      .attr("class", "mappings-bubble") // Add the class here
      .attr("r", d => d.r)
      .style("fill", "var(--primary-color)");

    circle.append("title")
      .text(d => `${d.data.ontology_name}\n${d.value}`);

    // Display ontology names in 16px white
    const textOntology = node.append("text")
      .attr("dy", ".35em")
      .style("text-anchor", "middle")
      .style("font-size", "16px")
      .style("fill", "white")
      .text(d => d.r > 20 ? d.data.ontology_name : "");

    // Display number of mappings in 12px white below ontology names
    const textMappings = node.append("text")
      .attr("dy", "1.5em")
      .style("text-anchor", "middle")
      .style("font-size", "12px")
      .style("fill", "white")
      .text(d => d.r > 20 ? d.data.ontology_mappings : "");

    // Display ontology names in tooltips on hover
    circle.on("mouseover", function (event, d) {
      d3.select(this).append("title")
        .text(`${d.data.ontology_name}\n${d.value}`);
    }).on("mouseout", function (event, d) {
      d3.select(this).select("title").remove();
    });

    this.svg = svg;
  }
}





data = [
    { ontology_name: 'ont1', ontology_mappings: 56 },
    { ontology_name: 'ont2', ontology_mappings: 33 },
    { ontology_name: 'ont3', ontology_mappings: 78 },
    { ontology_name: 'ont4', ontology_mappings: 21 },
    { ontology_name: 'ont5', ontology_mappings: 45 },
    { ontology_name: 'ont6', ontology_mappings: 89 },
    { ontology_name: 'ont7', ontology_mappings: 12 },
    { ontology_name: 'ont8', ontology_mappings: 67 },
    { ontology_name: 'ont9', ontology_mappings: 53 },
    { ontology_name: 'ont10', ontology_mappings: 30 },
    { ontology_name: 'ont11', ontology_mappings: 88 },
    { ontology_name: 'ont12', ontology_mappings: 42 },
    { ontology_name: 'ont13', ontology_mappings: 65 },
    { ontology_name: 'ont14', ontology_mappings: 17 },
    { ontology_name: 'ont15', ontology_mappings: 74 },
    { ontology_name: 'ont16', ontology_mappings: 26 },
    { ontology_name: 'ont17', ontology_mappings: 60 },
    { ontology_name: 'ont18', ontology_mappings: 38 },
    { ontology_name: 'ont19', ontology_mappings: 81 },
    { ontology_name: 'ont20', ontology_mappings: 49 },
    { ontology_name: 'ont21', ontology_mappings: 93 },
    { ontology_name: 'ont22', ontology_mappings: 14 },
    { ontology_name: 'ont23', ontology_mappings: 70 },
    { ontology_name: 'ont24', ontology_mappings: 36 },
    { ontology_name: 'ont25', ontology_mappings: 79 },
    { ontology_name: 'ont26', ontology_mappings: 23 },
    { ontology_name: 'ont27', ontology_mappings: 55 },
    { ontology_name: 'ont28', ontology_mappings: 98 },
    { ontology_name: 'ont29', ontology_mappings: 10 },
    { ontology_name: 'ont30', ontology_mappings: 62 },
    { ontology_name: 'ont31', ontology_mappings: 32 },
    { ontology_name: 'ont32', ontology_mappings: 68 },
    { ontology_name: 'ont33', ontology_mappings: 41 },
    { ontology_name: 'ont34', ontology_mappings: 84 },
    { ontology_name: 'ont35', ontology_mappings: 19 },
    { ontology_name: 'ont36', ontology_mappings: 72 },
    { ontology_name: 'ont37', ontology_mappings: 28 },
    { ontology_name: 'ont38', ontology_mappings: 59 },
    { ontology_name: 'ont39', ontology_mappings: 95 },
    { ontology_name: 'ont40', ontology_mappings: 15 },
    { ontology_name: 'ont41', ontology_mappings: 76 },
    { ontology_name: 'ont42', ontology_mappings: 24 },
    { ontology_name: 'ont43', ontology_mappings: 57 },
    { ontology_name: 'ont44', ontology_mappings: 87 },
    { ontology_name: 'ont45', ontology_mappings: 11 },
    { ontology_name: 'ont46', ontology_mappings: 64 },
    { ontology_name: 'ont47', ontology_mappings: 33 },
    { ontology_name: 'ont48', ontology_mappings: 69 },
    { ontology_name: 'ont49', ontology_mappings: 37 },
    { ontology_name: 'ont50', ontology_mappings: 80 },
    { ontology_name: 'ont51', ontology_mappings: 54 },
    { ontology_name: 'ont52', ontology_mappings: 87 },
    { ontology_name: 'ont53', ontology_mappings: 18 },
    { ontology_name: 'ont54', ontology_mappings: 71 },
    { ontology_name: 'ont55', ontology_mappings: 29 },
    { ontology_name: 'ont56', ontology_mappings: 63 },
    { ontology_name: 'ont57', ontology_mappings: 99 },
    { ontology_name: 'ont58', ontology_mappings: 13 },
    { ontology_name: 'ont59', ontology_mappings: 66 },
    { ontology_name: 'ont60', ontology_mappings: 35 },
    { ontology_name: 'ont61', ontology_mappings: 73 },
    { ontology_name: 'ont62', ontology_mappings: 21 },
    { ontology_name: 'ont63', ontology_mappings: 58 },
    { ontology_name: 'ont64', ontology_mappings: 92 },
    { ontology_name: 'ont65', ontology_mappings: 16 },
    { ontology_name: 'ont66', ontology_mappings: 83 },
    { ontology_name: 'ont67', ontology_mappings: 47 },
    { ontology_name: 'ont68', ontology_mappings: 82 },
    { ontology_name: 'ont69', ontology_mappings: 31 },
    { ontology_name: 'ont70', ontology_mappings: 75 },
    { ontology_name: 'ont71', ontology_mappings: 27 },
    { ontology_name: 'ont72', ontology_mappings: 61 },
    { ontology_name: 'ont73', ontology_mappings: 90 },
    { ontology_name: 'ont74', ontology_mappings: 44 },
    { ontology_name: 'ont75', ontology_mappings: 86 },
    { ontology_name: 'ont76', ontology_mappings: 22 },
    { ontology_name: 'ont77', ontology_mappings: 53 },
    { ontology_name: 'ont78', ontology_mappings: 97 },
    { ontology_name: 'ont79', ontology_mappings: 9 },
    { ontology_name: 'ont80', ontology_mappings: 51 },
    { ontology_name: 'ont81', ontology_mappings: 34 },
    { ontology_name: 'ont82', ontology_mappings: 77 },
    { ontology_name: 'ont83', ontology_mappings: 25 },
    { ontology_name: 'ont84', ontology_mappings: 67 },
    { ontology_name: 'ont85', ontology_mappings: 94 },
    { ontology_name: 'ont86', ontology_mappings: 43 },
    { ontology_name: 'ont87', ontology_mappings: 72 },
    { ontology_name: 'ont88', ontology_mappings: 12 },
    { ontology_name: 'ont89', ontology_mappings: 50 },
    { ontology_name: 'ont90', ontology_mappings: 85 },
    { ontology_name: 'ont91', ontology_mappings: 40 },
    { ontology_name: 'ont92', ontology_mappings: 74 },
    { ontology_name: 'ont93', ontology_mappings: 26 },
    { ontology_name: 'ont94', ontology_mappings: 69 },
    { ontology_name: 'ont95', ontology_mappings: 98 },
    { ontology_name: 'ont96', ontology_mappings: 14 },
    { ontology_name: 'ont97', ontology_mappings: 56 },
    { ontology_name: 'ont98', ontology_mappings: 31 },
    { ontology_name: 'ont99', ontology_mappings: 63 },
    { ontology_name: 'ont100', ontology_mappings: 36 }
]
