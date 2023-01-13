# frozen_string_literal: true

module KGCL
  class TemplateRenderer
    attr_reader :title_template, :body_template, :bind

    def initialize(title_template:, body_template:, bind_klass:)
      prefix = "#{Rails.root}/app/lib/kgcl/templates/"
      @title_template = File.join(prefix, title_template)
      @body_template = File.join(prefix, body_template)
      @bind = bind_klass.get_binding
    end

    def render
      result = {}
      result[:title] = title
      result[:body] = body
      result
    end

    def title
      f = File.read(@title_template)
      ERB.new(f, trim_mode: '%<>').result(@bind)
    end

    def body
      f = File.read(@body_template)
      ERB.new(f, trim_mode: '<>').result(@bind)
    end
  end
end
