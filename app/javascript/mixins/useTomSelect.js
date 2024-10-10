import TomSelect from "tom-select"

export function useTomSelect(element, params, onChange = null) {
    const tom = new TomSelect(element,params)
    if(onChange){
        tom.on('change',onChange)
    }
    return tom;
}