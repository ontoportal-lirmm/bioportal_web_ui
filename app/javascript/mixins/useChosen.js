export function useChosen(element, params, onChange = null) {
    const chosen = $(element).chosen(params)
    if(onChange){
        chosen.change(onChange)
    }

    return chosen;
}