class Input::RadioChipComponent < ViewComponent::Base
    def initialize(label: nil, name: nil, value: nil, checked: false, onchange: nil)
        @label = label
        @name = name
        @value = value
        @checked = checked
        @onchange = onchange
    end

end