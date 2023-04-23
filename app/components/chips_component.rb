class ChipsComponent < ViewComponent::Base
    renders_one :count
    def initialize(name:, value:, checked: false)
        @name = name
        @value = value
        @checked = checked
    end

    def checked?
        @checked
    end
end