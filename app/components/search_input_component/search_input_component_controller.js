import {Controller} from "@hotwired/stimulus"
import useAjax from "../../javascript/mixins/useAjax";

// Connects to data-controller="search-input"
export default class extends Controller {
    static targets = ["input", "dropDown", "actionLink", "template"]
    static values = {
        items: Array,
        ajaxUrl: String,
        itemLinkBase: String,
        idKey: String,
        cache: {type: Boolean, default: true},
        scrollDown: {type: Boolean, default: true}
    }

    connect() {
        this.input = this.inputTarget
        this.dropDown = this.dropDownTarget
        this.actionLinks = this.actionLinkTargets
        this.items = this.itemsValue
    }

    search() {
        this.#searchInput()
    }

    prevent(event){
        event.preventDefault();
    }
    blur() {
        this.dropDown.style.display = "none";
        this.input.classList.remove("home-dropdown-active");
    }

    #inputValue() {
        return this.input.value.trim()
    }

    #useCache() {
        return this.cacheValue
    }
    #scrollDownEnabled(){
        return this.scrollDownValue
    }

    #scrollDown(currentScroll) {
        const startPosition = window.pageYOffset;
        const distance = 300 - currentScroll;
        const duration = 1000;
        let start = null;

        function scrollAnimation(timestamp) {
            if (!start) start = timestamp;
            const progress = timestamp - start;
            const scrollPosition = startPosition + easeInOutCubic(progress, 0, distance, duration);
            window.scrollTo(0, scrollPosition);
            if (progress < duration) {
                window.requestAnimationFrame(scrollAnimation);
            }
        }

        function easeInOutCubic(t, b, c, d) {
            t /= d / 2;
            if (t < 1) return c / 2 * t * t * t + b;
            t -= 2;
            return c / 2 * (t * t * t + 2) + b;
        }

        window.requestAnimationFrame(scrollAnimation);
    }

    #fetchItems() {
        if (this.items.length !== 0 && this.#useCache()) {
            this.#renderLines()
        } else {
            useAjax({
                type: "GET",
                url: this.ajaxUrlValue + '?search=' + this.#inputValue(),
                dataType: "json",
                success: (data) => {
                    this.items = data.map(x => { return {...x, link: (this.itemLinkBaseValue + x[this.idKeyValue])}} )
                    this.#renderLines()
                },
                error: () => {
                    console.log("error")
                    //TODO show errors
                }
            })
        }
    }

    #renderLines() {
        const inputValue = this.#inputValue();
        let results_list = []
        if (inputValue.length > 0) {

            this.actionLinks.forEach(action => {
                const content = action.querySelector('p')
                content.innerHTML = inputValue
                const currentURL = new URL(action.href, document.location)
                currentURL.searchParams.set(currentURL.searchParams.keys().next().value, inputValue)
                action.href = currentURL.pathname + currentURL.search
            })

            this.dropDown.innerHTML = ""
            let breaker = 0
            for (let i = 0; i < this.items.length; i++) {
                if (breaker === 4) {
                    break;
                }
                // Get the current item from the ontologies array
                const item = this.items[i];

                let text =  Object.values(item).reduce((acc, value) => acc + value, "")


                // Check if the item contains the substring
                if (text.toLowerCase().includes(inputValue.toLowerCase())) {
                    results_list.push(item);
                    breaker = breaker + 1
                }
            }

            results_list.forEach((item) => {
                let link = this.#renderLine(item);
                this.dropDown.appendChild(link);
            });

            this.actionLinks.forEach(x => this.dropDown.appendChild(x))
            this.dropDown.style.display = "block";

            this.input.classList.add("home-dropdown-active");
            if ((window.scrollY < 300) && this.#scrollDownEnabled()) {
                this.#scrollDown(window.scrollY);
            }

        } else {
            this.dropDown.style.display = "none";
            this.input.classList.remove("home-dropdown-active");
        }

    }

    #renderLine(item) {
        let template = this.templateTarget.content
        let newElement = template.firstElementChild
        let string = newElement.outerHTML

        Object.entries(item).forEach( ([key, value]) => {
            key = key.toString().toUpperCase()
            if (key === 'TYPE'){
                value  = value.toString().split('/').slice(-1)
            }
            string =  string.replace(key, value.toString())
        })

        return new DOMParser().parseFromString(string, "text/html").body.firstElementChild
    }

    #searchInput() {
        this.#fetchItems()
    }
}
