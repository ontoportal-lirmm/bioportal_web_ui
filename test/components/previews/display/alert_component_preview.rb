class Display::AlertComponentPreview < ViewComponent::Preview

  #@param message text
  #@param closable select [true, false]
  def default(message: "New ontology Bioinformatics Ontology v2.0 has been uploaded. Check it out in the latest uploads section", closable: true)
    render Display::AlertComponent.new(message: message, closable: closable)
  end

  #@param message text
  #@param closable select [true, false]
  def danger(message: "Unable to delete ontology Chemistry Concepts Ontology. This ontology is associated with existing mappings. Please remove mappings before deleting", closable: true)
    render Display::AlertComponent.new(message: message, closable: closable, type: "danger")
  end

  #@param message text
  #@param closable select [true, false]
  def warning(message: "This ontology version is outdated and may contain inaccuracies. Consider using the latest version for accurate information", closable: true)
    render Display::AlertComponent.new(message: message, closable: closable, type: "warning")
  end

  #@param message text
  #@param closable select [true, false]
  def success(message: "Your ontology submission has been successfully uploaded and is now under review. You will receive an email confirmation shortly", closable: true)
    render Display::AlertComponent.new(message: message, closable: closable, type: "success")
  end


  #@param message text
  #@param delay number
  def auto_close(message: "Your ontology submission has been successfully uploaded and is now under review. You will receive an email confirmation shortly", delay: 3000)
    render Display::AlertComponent.new(message: message, closable: true, auto_close_delay: delay, type: "default")
  end

end