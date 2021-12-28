//TODO extends ConceptLabelLink when we implement a js bundler in rails 6
class AjaxConceptLabelLink   {

    static render(ontologyAcronym, conceptId ,  target){
        return ConceptLabelLink.render(conceptId, InstancesHelper.getClassHref(conceptId) , target , conceptId+ this.getAjaxSpanRender(ontologyAcronym , conceptId))
    }

    static getAjaxSpanRender(ontologyAcronym ,conceptId){
       return `<span href='/ajax/classes/label?ontology=${ontologyAcronym}&concept=${encodeURIComponent(conceptId)}'
               class='get_via_ajax'></span>`
    }
}