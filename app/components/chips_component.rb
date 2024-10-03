class ChipsComponent < ViewComponent::Base

    renders_one :count
    def initialize(id:nil, name:,  label: nil, value: nil, checked: false, tooltip: nil, disabled: false)
        @id = id || name
        @name = name
        @value = value || 'true'
        @checked = checked
        @label = label || @value
        @tooltip = tooltip
        @disabled = disabled
    end

    def checked?
        @checked
    end
end
