class ChipsComponent < ViewComponent::Base

    renders_one :count
    def initialize(id:nil, name:,  label: nil, value: nil, checked: false, tooltip: nil, disabled: false, loading: false)
        @id = id || name
        @name = name
        @value = value || 'true'
        @checked = checked
        @label = label || @value
        @tooltip = tooltip
        @disabled = disabled
        @loading = loading
    end

    def checked?
        @checked
    end

    def disabled_class_name
        @disabled ? 'disabled' : ''
    end

    def loading_class_name
        @loading ? 'loading' : ''
    end
end
