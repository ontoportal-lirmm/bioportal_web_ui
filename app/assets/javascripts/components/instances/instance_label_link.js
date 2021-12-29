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
        let chosenLabel = InstancesHelper.getLabelFrom(instance)
        href ||= InstancesHelper.getInstanceHref(instance.uri)

        return ConceptLabelLink.render(instance.uri, href , target , chosenLabel )
    }
}