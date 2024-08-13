import {Controller} from "@hotwired/stimulus"
import useAjax from "../../javascript/mixins/useAjax";
import debounce from 'debounce'

// Connects to data-controller="search-input"
export default class extends Controller {
    static targets = ["input", "dropDown", "actionLink", "template", "button", "loader"]
    static values = {
        items: Array,
        ajaxUrl: String,
        itemLinkBase: String,
        idKey: String,
        cache: {type: Boolean, default: true},
        selectedItem: Number,
        searchEndpoint: {type: String, default: '/search'},
        displayAll: Boolean
    }

    connect() {
        this.input = this.inputTarget
        this.dropDown = this.dropDownTarget
        this.actionLinks = this.actionLinkTargets
        this.items = this.itemsValue
        this.search = debounce(this.search.bind(this), 100);
    }

    search() {
        this.selectedItemValue = 0
        this.loaderTarget.classList.remove("d-none")
        this.buttonTarget.classList.add("d-none")
        this.searchInput()
    }

    searchInput() {
        this.#fetchItems()
    }

    prevent(event){
        event.preventDefault();
    }
    blur() {
        this.dropDown.style.display = "none";
        this.input.classList.remove("home-dropdown-active");
    }
    arrow_up(){
        if (this.selectedItemValue > 1){
            this.selectedItemValue--
            this.dropDownTarget.querySelectorAll('.search-content')[this.selectedItemValue-1].style.backgroundColor = "rgba(0, 0, 0, 0.03)";
            this.dropDownTarget.querySelectorAll('.search-content')[this.selectedItemValue].style.background = 'white'
        }
    }
    arrow_down(){
        if(this.selectedItemValue<this.dropDownTarget.querySelectorAll('.search-content').length){
            this.selectedItemValue++
        }
        this.dropDownTarget.querySelectorAll('.search-content')[this.selectedItemValue-1].style.backgroundColor = "rgba(0, 0, 0, 0.03)";
        if(this.selectedItemValue > 1){
            this.dropDownTarget.querySelectorAll('.search-content')[this.selectedItemValue-2].style.background = 'white'
        } 
    }
    enter_key(){
        if(this.inputTarget.value != ''){
            let results = this.dropDownTarget.querySelectorAll('.search-content')
            if(this.selectedItemValue === 0 || this.dropDownTarget.style.display === 'none'){
                results[results.length - 2].click()
            } else {
                results[this.selectedItemValue-1].click()
            }
        }        
    }
    #inputValue() {
        return this.input.value.trim()
    }

    #useCache() {
        return this.cacheValue
    }


    #fetchItems() {
        if (this.items.length !== 0 && this.#useCache()) {
            this.#renderLines()
        } else {
            useAjax({
                type: "GET",
                url: this.ajaxUrlValue + encodeURIComponent(this.#inputValue()),
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
        this.loaderTarget.classList.add("d-none")
        this.buttonTarget.classList.remove("d-none")
        const inputValue = this.#inputValue();
        let results_list = []
        if (inputValue.length > 0) {
            this.buttonTarget.href = `${this.searchEndpointValue}?q=${inputValue}`;
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
                if (!this.displayAllValue && breaker === 4) {
                    break;
                }
                // Get the current item from the ontologies array
                const item = this.items[i];

                let text =  Object.values(item).reduce((acc, value) => acc + value, "")
                
                // Check if the item contains the substring
                if (!this.cacheValue || text.toLowerCase().includes(inputValue.toLowerCase())) {
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


        } else {
            this.dropDown.style.display = "none";
            this.input.classList.remove("home-dropdown-active");
        }

    }

    #renderLine(item) {
        let template = this.templateTarget.content
        let newElement = template.firstElementChild.outerHTML
        Object.entries(item).forEach( ([key, value]) => {
            key = key.toString().toUpperCase()
            if (key === 'TYPE'){
                value  = value.toString().split('/').slice(-1)
            }
            if (key === 'ACRONYM'){
                value = value ? `(${value.toString()})` : ''
            }
            if (key === 'IDENTIFIERS'){
                value = value ? `- ${value.toString()}` : ''
            }
            const regex = new RegExp('\\b' + key + '\\b', 'gi');
            newElement =  newElement.replace(regex, value ? value.toString() : "")
        })
        
        return new DOMParser().parseFromString(newElement, "text/html").body.firstElementChild
    }
}
