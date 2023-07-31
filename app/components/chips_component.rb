class ChipsComponent < ViewComponent::Base
    def initialize(id: '',name:, value:)
        @id = id || name
        @name = name
        @value = value
    end
end