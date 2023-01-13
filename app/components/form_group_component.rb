# frozen_string_literal: true

class FormGroupComponent < ViewComponent::Base
  include Turbo::FramesHelper
  attr_reader :method_name, :value, :name
  renders_one :help
  renders_one :label
  renders_one :input
  renders_one :submit


  def initialize(object:nil, name: '', method: nil, label: '', required: false, inline: true)
    @object_name = object.class.name
    @method_name = method || ''
    @value = object.send(method) if object && method
    @label_text = label && !label.empty? ? label : method.to_s.capitalize
    @required = required
    @name = name && !name.empty? ? name : @object_name
    @inline = inline
  end


  def required?
    @required
  end

  def inline_label?
    @inline
  end

  def label_class
    inline_label? ? 'col-sm-4' : ''
  end
  def content_class
    inline_label? ? 'col-sm-8' : ''
  end
  def container_class
    inline_label? ? 'row' : ''
  end
  def container_id
    "#{@name}#{@method_name.capitalize}"
  end
end
