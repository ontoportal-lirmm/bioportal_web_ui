# frozen_string_literal: true

class Input::LanguageSelectorComponent < ViewComponent::Base

  def initialize(languages:, selected: nil,  id: '', name: '' )
    super
    @languages = languages
    @id = id
    @name = languages
    @selected = selected
  end

  def languages_options
    values = [['All languages', 'all']]

    @languages.each do |key, label|
      option = "<div>#{render(LanguageFieldComponent.new(value: key.to_s.downcase, label: label))}</div>"
      values += [[option, key.to_s.downcase]]
    end
    values
  end

  def call
    render SelectInputComponent.new(id: @id, name: @name, values: languages_options, selected: @selected, placeholder: 'Select a language')
  end
end
