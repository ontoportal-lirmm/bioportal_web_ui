module ErrorHelpers
  def self.not_browsable_text(concept)
    case concept.type.downcase
    when "individual"
      return "Sorry, the class <strong>#{concept.label}</strong> cannot be viewed because it refers to an individual"
    when "property"
      return "Sorry, the class <strong>#{concept.label}</strong> cannot be viewed because it refers to a property"
    else
      return "Sorry, an error has occurred"
    end
  end
end
