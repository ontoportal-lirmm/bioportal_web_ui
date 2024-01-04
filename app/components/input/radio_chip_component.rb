class Input::RadioChipComponent < ViewComponent::Base
    def initialize(label: nil, name: nil, value: nil, checked: false)
        @label = label
        @name = name
        @value = value
        @checked = checked
    end

end