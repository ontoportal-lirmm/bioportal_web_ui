import tippy from 'tippy.js';

export default function useTooltip(elem, params) {
    const content = elem.title
    elem.removeAttribute('title')
    tippy(elem, {
        theme: 'light-border',
        animation: 'fade',
        content: content,
        allowHTML: true,
        placement: 'top',
        maxWidth: '400', ...params
    })
}