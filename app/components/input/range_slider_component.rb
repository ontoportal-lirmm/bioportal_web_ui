

class Input::RangeSliderComponent < ViewComponent::Base
    def initialize(name: nil, label: nil ,value: '50', min: '0', max: '100', step: '1')
        @name = name
        @label = label
        @value = value
        @min = min
        @max = max
        @step = step
    end

end