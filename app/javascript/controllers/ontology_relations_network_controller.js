import {Controller} from "@hotwired/stimulus"
import { Network, DataSet } from 'vis-network/standalone/esm/vis-network.min.js';

// Connects to data-controller="ontology-relations-network"
export default class extends Controller {
    static values = {
        data: Array
    }

    static targets = ["container"]

    connect() {
        this.build()
    }


    build(){
        this.#buildNetwork(this.dataValue);
    }
    /**
     * Build the VIS network for ontologies relations: http://visjs.org/docs/network/
     * @param ontologyRelationsArray
     */
    #buildNetwork(ontologyRelationsArray) {
        const nodes = new DataSet([])
        // create an array with edges
        const edges = new DataSet();

        let propertyCount = 1; // To define nodes IDs

        // Hash with nodes id for each ontology URI
        let nodeIds = {};

        /* Get the relations that have been selected
        if (jQuery("#selected_relations").val() !== null) {
          selected_relations = jQuery("#selected_relations").val()
        }*/

        let selected_relations = [];
        this.relationCheckTargets = Array.from(this.element.querySelectorAll('option'))
        this.relationCheckTargets.forEach((elem) => {
            if (elem.selected) {
                selected_relations.push(elem.value);
            }
        })

        ontologyRelationsArray.forEach((relation) => {
            let targetNodeNumber
            let sourceNodeNumber

            // If relations have been selected for filtering then we don't show others relations
            if (!selected_relations.includes(relation["relation"])) {
                return
            }

            // Don't create a new node if node exist already, just add a new edge
            if ( nodeIds[relation["source"]] != null) {
                sourceNodeNumber = nodeIds[relation["source"]];
            } else {
                sourceNodeNumber = propertyCount;
                // If the node is the source it means it is from the Portal, so we colorate it in green
                nodes.add([
                    {id: sourceNodeNumber, label: relation["source"], color: "#5cb85c"}
                ]);
                nodeIds[relation["source"]] = propertyCount;
                propertyCount++;
            }

            // Create the target node if don't exist
            if (nodeIds[relation["target"]] != null) {
                targetNodeNumber = nodeIds[relation["target"]];
            } else {
                targetNodeNumber = propertyCount;
                // If target node is an ontology from the portal then node in green
                if (relation["targetInPortal"]) {
                    nodes.add([
                        {id: targetNodeNumber, label: relation["target"], color: "#5cb85c"}
                    ]);
                } else {
                    nodes.add([
                        {id: targetNodeNumber, label: relation["target"]}
                    ]);
                }
                nodeIds[relation["target"]] = propertyCount;
                propertyCount++;
            }

            edges.add([
                {
                    from: sourceNodeNumber,
                    to: targetNodeNumber,
                    label: relation["relation"],
                    font: {align: 'horizontal'}
                }
            ]);
        })



        // create a network
        const container = this.containerTarget;
        // provide the data in the vis format

        const data = {
            nodes: nodes,
            edges: edges
        };

        // Get height of div
        const networkHeight = container.clientHeight.toString();

        const options = {
            autoResize: true,
            height: networkHeight,
            groups: {
                useDefaultGroups: true,
                myGroupId: {
                    /*node options*/
                }
            },
            edges: {
                color: {inherit: 'both'},
                smooth: {
                    enabled: true,
                    type: "dynamic",
                    roundness: 0.5
                }
            },
            nodes: {
                shape: "box"
            },
            physics: {
                // http://visjs.org/docs/network/physics.html
                enabled: true,
                // To stabilize faster, increase the minVelocity value
                minVelocity: 1,
                stabilization: {
                    enabled: true,
                    onlyDynamicEdges: false,
                    fit: true
                },
                barnesHut: {
                    gravitationalConstant: -1500,
                    centralGravity: 0,
                    springLength: 300,
                    springConstant: 0.01,
                    damping: 0.2,
                    avoidOverlap: 0.2
                },
                hierarchicalRepulsion: { // not used at the moment
                    centralGravity: 0.0,
                    springLength: 500,
                    springConstant: 0.2,
                    damping: 1,
                    nodeDistance: 170
                },
                solver: 'barnesHut'
            },
            interaction: {
                zoomView: false,
                navigationButtons: true
            }
        };

        // initialize your network!
        const network = new Network(container, data, options);
        network.fit();
        // Add a button click event listener
        var fullscreenButton = document.getElementById('fullscreen-button');
        fullscreenButton.addEventListener('click', function () {
            toggleFullScreen(container);
        });

        // Function to toggle full screen mode
        function toggleFullScreen(element) {
            var networkContainer = document.getElementById('networkContainer');

            // check to existance of element
            if (networkContainer) {
                var parentElement = networkContainer.parentNode;

                // add style background: 
                parentElement.style.backgroundColor = 'white';
            }
            networkContainer.parentNode.classList.toggle('active-fullscreen');
            //element.children[0].canvas.classList.toggle('active-fullscreen')
        }
    }
}
