class ChipsComponent < ViewComponent::Base
    def initialize(name:, value:)
        @name = name
        @value = value
    end
end