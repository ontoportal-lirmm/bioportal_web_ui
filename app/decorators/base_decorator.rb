class BaseDecorator < SimpleDelegator
  attr_reader :view_context

  def initialize(object, view_context)
    __setobj__ object
    @view_context = view_context
  end

  def self.wrap_collection(objects, view_context)
    objects.map { |object| new(object, view_context) }
  end
end
