class ChipsComponent < ViewComponent::Base
    renders_one :count
    def initialize(name:, value:, label: nil,checked: false)
        @name = name
        @value = value
        @checked = checked
        @label = label || @value
    end

    def checked?
        @checked
    end
end