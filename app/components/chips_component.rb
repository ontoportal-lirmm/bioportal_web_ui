class ChipsComponent < ViewComponent::Base
    def initialize(id: '', name:, value:, checked: false)
        @id = id || name
        @name = name
        @value = value
        @checked = checked
    end

    def checked?
        @checked
    end
end