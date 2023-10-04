import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="metadata-downloader"
export default class extends Controller {
    connect() {
    }

    downloadNQuads() {
        this.#downloadMetadata("nquads")
    }

    downloadJsonLd() {
        this.#downloadMetadata("jsonld")
    }

    downloadXML() {
        this.#downloadMetadata("xml");
    }

    /**
     * Format submission metadata to be downloaded
     * @param format
     */
    #downloadMetadata(format) {

        jQuery.get(
            // Get the submission metadata infos
            jQuery(document).data().bp.config.rest_url + "/submission_metadata?apikey=" + jQuery(document).data().bp.config.apikey,
            (subMetadataArray) => {
                var subMetadataHash = {};
                // Convert submission metadata array to a hash to be faster
                for (var i = 0; i < subMetadataArray.length; i++) {
                    subMetadataHash[subMetadataArray[i]["attribute"]] = subMetadataArray[i];
                }
                var jsonldObject = {}
                var added_props = {}

                var subJson = jQuery.extend(true, {}, jQuery(document).data().bp.submission_latest);
                var ontJson = jQuery(document).data().bp.ontology;
                var fullContext = jQuery(document).data().bp.submission_latest["context"];

                // Remove links, context and metrics from json
                delete subJson["links"];
                delete subJson["context"];
                delete subJson["metrics"];

                // Special case for publication and released that don't have namespace (so value generated to undefined)
                fullContext["publication"] = "http://omv.ontoware.org/2005/05/ontology#reference";
                fullContext["released"] = "http://purl.org/dc/terms/date";

                // Add ontology properties to context and subJson
                subJson["viewOf"] = ontJson["viewOf"];
                fullContext["viewOf"] = "http://data.bioontology.org/metadata/viewOf";

                subJson["group"] = ontJson["group"];
                fullContext["group"] = "http://data.bioontology.org/metadata/group";
                if (subJson["hasDomain"] == null) {
                    subJson["hasDomain"] = ontJson["hasDomain"];
                } else {
                    subJson["hasDomain"] = subJson["hasDomain"].split(", ").concat(ontJson["hasDomain"]);
                    /* make the array unique:
                     var unique = arr.filter(function(elem, index, self) {
                     return index == self.indexOf(elem);
                     })
                     */
                }


                // Don't add null value and empty arrays
                for (var attr in subJson) {
                    if (subJson[attr] === null || subJson[attr] === undefined) {
                        continue;
                    } else if (subJson[attr] instanceof Array && subJson[attr].length < 1) {
                        continue;
                    }
                    // Keep only metadata that have been extracted, are metrics or are in the metadata array below
                    var metadata_in_rdf = ["acronym", "name", "hasOntologyLanguage", "creationDate", "released", "group", "viewOf"]
                    if (subMetadataHash[attr] != undefined && subMetadataHash[attr]["extracted"] !== true && subMetadataHash[attr]["display"] !== "metrics"
                        && !metadata_in_rdf.indexOf(attr)) {

                        continue;
                    }

                    if (fullContext[attr] !== undefined) {
                        // Add attr value to future jsonld object and keep track of the attr we added to build context
                        if (subMetadataHash[attr] != undefined) {
                            added_props[attr] = subMetadataHash[attr]["namespace"] + ":" + attr;
                        } else {
                            added_props[attr] = "bpm:" + attr;
                        }
                        jsonldObject[fullContext[attr]] = subJson[attr];
                    }
                }

                // Add id and type
                if (subJson["URI"] !== null) {
                    jsonldObject["@id"] = subJson["URI"];
                } else {
                    jsonldObject["@id"] = ontJson["id"];
                }
                jsonldObject["@type"] = "http://www.w3.org/2002/07/owl#Ontology";

                // Get only context from returned properties
                let context = {};
                for (let prop in added_props) {
                    context[prop] = fullContext[prop];
                    if (context[prop] == undefined) {
                        // If property URI not defined then we create it with bioontology.org URI
                        context[prop] = "http://data.bioontology.org/metadata/" + prop;
                    }
                }

                let responseString = "Error while generating the RDF"
                if (format === "nquads") {
                    jsonld.toRDF(jsonldObject, {format: 'application/nquads'},  (err, nquads) => {
                        this.#generateDownloadFile(nquads, "nt")
                    });
                } else if (format === "jsonld") {
                    // Generate proper jsonld
                    jsonld.compact(jsonldObject, context,  (err, compacted) => {
                        this.#generateDownloadFile(JSON.stringify(compacted, null, 2), "json");
                    });
                } else if (format === "xml") {
                    // Generate RDF/XML
                    this.#generateDownloadFile(this.#generateRdfXml(jsonldObject, subMetadataHash), "rdf");
                }
            }
        );
    }

    /**
     * Generate the RDF/XML string from the jsonldObject and context. Do it manually since no good lib
     * @param jsonldObject
     * @param context
     */
    #generateRdfXml(jsonldObject, metadataDetails) {

        // Get hash to resolve namespace
        var resolveNamespace = jQuery(document).data().bp.config.resolve_namespace;

        var xmlString = `<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl#">
  <rdf:Description rdf:about="` + jsonldObject["@id"] + `">
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Ontology"/>`;

        delete jsonldObject["@id"];
        delete jsonldObject["@type"];

        for (var prop in jsonldObject) {
            var attr_uri = prop;
            var attr = prop;
            // Here we replace the full URI by namespace:attr
            for (var ns in resolveNamespace) {
                if (prop.indexOf(resolveNamespace[ns]) == 0) {
                    prop = prop.replace(resolveNamespace[ns], ns + ":");
                    attr = attr.replace(resolveNamespace[ns], "");
                    break;
                }
            }

            // Check if the value is an URI using simple regex
            var prop_values = jsonldObject[attr_uri];
            if (!(prop_values instanceof Array)) {
                prop_values = [prop_values];
            }

            for (var i in prop_values) {
                var prop_value = prop_values[i];
                if ((prop_value.toString().match(/https?:\/\//g) || []).length === 1 && prop_value.toString().indexOf(" ") === -1) {
                    xmlString = xmlString.concat(`
    <` + prop + ` rdf:resource="` + prop_value + `"/>`);
                } else {
                    xmlString = xmlString.concat(`
    <` + prop + `/>` + jsonldObject[attr_uri] + `<` + prop + `/>`);
                }
            }

        }

        xmlString = xmlString.concat(`
  </rdf:Description>
</rdf:RDF>`);

        return xmlString;
    }

    /**
     * Generate the file with metadata to be downloaded, given the file content
     * @param content
     * @param fileExtension
     */
    #generateDownloadFile(content, fileExtension) {
        var element = document.createElement('a');
        // TODO: change MIME type?
        element.setAttribute('href', 'data:application/rdf+json;charset=utf-8,' + encodeURIComponent(content));
        element.setAttribute('download', jQuery(document).data().bp.ontology.acronym + "_metadata." + fileExtension);

        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }
}


