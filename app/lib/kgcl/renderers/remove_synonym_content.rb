# frozen_string_literal: true

class RemoveSynonymContent
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def render
    tr = KGCL::TemplateRenderer.new(
      title_template: 'remove_synonym_title.erb',
      body_template: 'remove_synonym_body.erb',
      bind_klass: self
    )
    tr.render
  end

  def comment
    @params[:comment]
  end

  def curie
    @params[:curie]
  end

  def get_binding
    binding
  end

  def pref_label
    @params[:pref_label]
  end

  def synonym
    @params[:synonym]
  end

  def username
    @params[:username]
  end
end
