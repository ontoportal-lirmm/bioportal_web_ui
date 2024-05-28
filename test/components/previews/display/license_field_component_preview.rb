class Display::LicenseFieldComponentPreview < ViewComponent::Preview

  # @param value select [	CC-BY IGO 3.0, https://creativecommons.org/licenses/by/4.0/, http://www.gnu.org/licenses/gpl-3.0, https://opensource.org/licenses/MIT, http://www.apache.org/licenses/LICENSE-2.0  ]
  def default(value: "https://creativecommons.org/licenses/by/4.0/")
    render LicenseFieldComponent.new(value: value)
  end

end