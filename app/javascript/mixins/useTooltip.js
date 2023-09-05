import tippy from 'tippy.js';

export default function useTooltip(elem) {
    const content = elem.title
    elem.removeAttribute('title')
    tippy(elem, {
        theme: 'light-border',
        animation: 'fade',
        content: content,
        allowHTML: true,
        placement: 'top',
        interactive: true,
        maxWidth: '400'
    })
}