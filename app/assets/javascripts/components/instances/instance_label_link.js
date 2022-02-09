//TODO extends ConceptLabelLink when we implement a js bundler in rails 6
class InstanceLabelLink {

    /**
     *
     * @param instance {Instance}
     * @param href
     * @param target
     * @returns {string}
     */
    static render(instance , href = "" , target=""){
        const choseInstanceClass = (instance) => {
            const EXCEPT_TYPES = ["http://www.w3.org/2002/07/owl#NamedIndividual"]
            let out = instance.types.filter(x => !EXCEPT_TYPES.find(type => x === type))
            if(out.length >0)
                return out[0]
            else
                return ""
        }

        let chosenLabel = InstancesHelper.getLabelFrom(instance)
        let chosenClass = choseInstanceClass(instance)

        href ||= InstancesHelper.getInstanceHref(instance.uri , chosenClass)

        return ConceptLabelLink.render(instance.uri, href , target , chosenLabel )
    }
}