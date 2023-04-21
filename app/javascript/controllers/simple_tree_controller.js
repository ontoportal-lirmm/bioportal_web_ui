import {Controller} from "@hotwired/stimulus"
import {useSimpleTree} from "../mixins/useSimpleTree";

// Connects to data-controller="simple-tree"
export default class extends Controller {

    static values = {
        autoClick: {type: Boolean, default: false}
    }

    connect() {
        this.simpleTreeCollection = useSimpleTree(this.element,
            this.#afterClick.bind(this),
            this.#afterAjaxError.bind(this),
            this.#beforeAjax.bind(this)
        )


        this.simpleTreeCollection.ready(() => {
            let activeElem = this.element.querySelector('a.active')
            if (activeElem) {
                $(this.element).scrollTo($(activeElem))

                if (this.autoClickValue) {
                    activeElem.click()
                }
            }


        })

        this.#onClickTooManyChildrenInit()
    }

    #onClickTooManyChildrenInit() {
        jQuery(".too_many_children_override").live('click', (event) => {
            event.preventDefault();
            let result = jQuery(event.target).closest("ul");
            result.html("<img src='/images/tree/spinner.gif'>");
            jQuery.ajax({
                url: jQuery(event.target).attr('href'),
                context: result,
                success: function (data) {
                    this.html(data);
                    this.simpleTreeCollection.get(0).setTreeNodes(this);
                },
                error: function () {
                    this.html("<div style='background: #eeeeee; padding: 5px; width: 80%;'>Problem getting children. <a href='" + jQuery(this).attr('href') + "' class='too_many_children_override'>Try again</a></div>");
                }
            });
        });
    }

    #afterClick(node) {
        this.element.dispatchEvent(new CustomEvent('clicked', {
            detail: {
                node: node,
                data: {...node.context.dataset}

            }
        }))
    }

    #afterAjaxError(node) {
        this.simpleTreeCollection[0].option.animate = false;
        this.simpleTreeCollection.get(0).nodeToggle(node.parent()[0]);
        if (node.parent().children(".expansion_error").length === 0) {
            node.parent().append("<span class='expansion_error'>Error, please try again");
        }
        this.simpleTreeCollection[0].option.animate = true;
    }

    #beforeAjax(node) {
        node.parent().children(".expansion_error").remove();
    }
}
