/**
 * Render a jquery data table of an ontology (and class) instances inside a <table> element
 */
class InstancesTable{
    constructor(tableElem , ontologyAcronym , classUri = ""){
        this.tableElem = tableElem
        this.ontologyAcronym = ontologyAcronym
        this.classUri = classUri
        this.dataTable = null
    }

    init(){
        if ( $.fn.dataTable.isDataTable( this.tableElem ) ) {
            $(this.tableElem).DataTable().destroy();

        }
        this.dataTable = $(this.tableElem).DataTable( {
            "paging": true,
            "pagingType": "full",
            "info": true,
            "searching": false,
            "ordering": false,
            "serverSide":true,
            "processing": true,
            "ajax": {
                "url": this.getAjaxUrl(),
                "contentType": "application/json",
                "dataSrc":  (json) => {
                    console.log(json)
                    json.recordsTotal = json["totalCount"];
                    json.recordsFiltered = json.recordsTotal
                    return  json["collection"].map(x => [
                        {id: x["@id"] , label: x["label"] , prefLabel:x["prefLabel"]},
                        x["types"],
                        x["properties"]
                    ])
                },
                "data": (d) => {
                    return {page: (d.start/d.length)+ 1 , pagesize: d.length}
                }
            },
            "columnDefs": this.render(),
            "language": {
                'loadingRecords': '&nbsp;',
                'processing': `           
                                <div class="spinner-border m-2" role="status"> 
                                    <span class="sr-only">Loading...</span>
                                </div>           
                `
            },
            "createdRow":  (row, data, dataIndex ) => {
                $(row).click(() => this.openPopUpDetail(data));
            }

        })
    }

    static mount(tableId , ontologyAcronym , conceptId){
        if(tableId.toString().length>0){
            const tableElm = document.querySelector(tableId)

            if(tableElm){
                const instanceTable = new InstancesTable( tableElm , ontologyAcronym , conceptId)
                instanceTable.init()
                return instanceTable
            }
        }
    }

    render(){

        let columns = [{
            "targets" : 0 ,
            "title": 'Instance',
            "render" : (data) => {
                let {id,label,prefLabel} = data
                return InstanceLabelLink.render( new Instance(id,label,prefLabel),"javascript:void(0)")

            }
        }]

        if(!this.isClassURISet())
            columns.push({
                "targets" : 1 ,
                "title": 'Types',
                "render" : (data) => data.map(x => AjaxConceptLabelLink.render(this.ontologyAcronym , x))
            })

        return  columns
    }

    getAjaxUrl(page= null , size = null) {
        let url = "/ajax/"+ this.ontologyAcronym
        let params =  ["page="+page,"pagesize="+size].filter(x => x !== null).join("&")
        if(this.isClassURISet() > 0){
            url += "/classes/" + encodeURIComponent(this.classUri)
        }
        url +=  "/instances" + (page!==null || size!=null ? "?"+params : "");
        return url
    }

    isClassURISet(){
        return this.classUri.length > 0
    }

    openPopUpDetail(data){

        $.facebox(() => {
            let {id} = data[0]
            let types = data[1]
            let properties = data[2]

            $.facebox( new InstanceDetails(this.ontologyAcronym, new Instance(id , "", "" ,types, properties)).render().html())
        })
    }
}