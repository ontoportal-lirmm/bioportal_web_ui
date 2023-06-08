export default function useTooltip(elem, position){
    $(elem).tooltipster({theme: 'tooltipster-shadow', contentAsHTML: true, position: position});
}