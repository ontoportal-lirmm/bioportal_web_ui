export const getCookie = (name) => {
    const cookieValue = document.cookie.match('(^|[^;]+)\\s*' + name + '\\s*=\\s*([^;]+)');
    return cookieValue ? cookieValue.pop() : '';
}

export const setCookie = (name, value, days) => {
    document.cookie = `${name}=${value};max-age=${days * 24 * 60 * 60}`;
}