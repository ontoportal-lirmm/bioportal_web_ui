class DateTimeFieldComponentPreview < ViewComponent::Preview

  # @param text text
  # @param format select [year_month_day_concise, month_day_year, monthfull_day_year]
  def default(text: "2022-10-01", format: 'monthfull_day_year')
    render DateTimeFieldComponent.new(value: text, format: format.to_sym)
  end

end