import {Controller} from "@hotwired/stimulus"
import useAjax from "../mixins/useAjax";

// Connects to data-controller="label-ajax"
export default class extends Controller {
    static values = {
        clsId: String,
        ontologyAcronym: String,
        ajaxUrl: String,
        clsIdUrl: String,
    }

    connect() {
        setTimeout(() => {
            this.linkA = jQuery(this.element);

            if (this.linkA.hasClass('ajax-modified-cls')) {
                return true
            }

            this.cls_id = this.clsIdValue;
            this.ont_acronym = this.ontologyAcronymValue;
    
            let ajax_uri = new URL(this.ajaxUrlValue, document.location.origin)
    
            ajax_uri.searchParams.set('ontology', this.ont_acronym)
            ajax_uri.searchParams.set('id', this.cls_id)
    
    
            this.request = useAjax({
                url: ajax_uri.pathname + ajax_uri.search,
                timeout: ajax_process_timeout * 1000,
                success: this.#ajaxSuccess.bind(this),
                error: this.#ajaxError.bind(this)
            });
          },1)
    }

    abort() {
        if (this.request) {
            this.request.abort()
            this.request = null
        }
    }

    disconnect() {
        this.abort()
    }

    #ajaxSuccess(data) {
        data = data.trim();
        if (typeof data !== "undefined" && data.length > 0 && data.indexOf("http") !== 0) {
            let cls_name = data
            let cls_uri = this.clsIdUrlValue
            this.linkA.html(cls_name);
            this.linkA.attr('href', cls_uri);
            this.linkA.addClass('ajax-modified-cls');
            //find and process any identical classes (low probability)
            this.#fillIdenticalIds(cls_name, cls_uri)
        } else {
            // remove the unique_id separator and the ontology acronym from the href
            this.linkA.attr('href', this.cls_id);  // it may not be an ontology class, don't use the cls_uri
            this.linkA.addClass('ajax-modified-cls');
        }
    }

    #ajaxError() {
        this.linkA.addClass('ajax-error')
    }

    #fillIdenticalIds(cls_name, cls_uri) {

        let unique_id = this.linkA.attr('href');
        jQuery('a[href="' + unique_id + '"]').each(function () {
            let link = jQuery(this);
            if (!link.hasClass('ajax-modified-cls')) {
                link.html(cls_name);
                link.attr('href', cls_uri);
                link.addClass('ajax-modified-cls')
            }
        });
    }
}
