export class UseModal {

    showModal(element) {
        $(element).modal('show')
    }

    hideModal(element) {
        $(element).modal('hide')
    }

    onClose(element, callback) {
        return $(element).on('hidden.bs.modal', callback)
    }
    onCloseRemoveEvent(element, callback){
        return element.removeEventListener('hidden.bs.modal', callback)
    }
}

