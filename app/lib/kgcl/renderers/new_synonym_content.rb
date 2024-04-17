# frozen_string_literal: true

module KGCL
  module Renderers
    # Generate GitHub issue content for a create synonym change request
    #
    # The change request is described using the Knowledge Graph Change Language grammar, e.g.:
    #
    #   create synonym 'single organism process' for 'GO:0008150'
    #   create synonym 'single organism process' @en for 'GO:0008150'
    #   create exact synonym 'single organism process' for 'GO:0008150'
    #
    # @see https://github.com/INCATools/kgcl KGCL documentation
    #
    class NewSynonymContent
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def render
        tr = KGCL::TemplateRenderer.new(
          title_template: 'new_synonym_title.erb',
          body_template: 'new_synonym_body.erb',
          bind_klass: self
        )
        tr.render
      end

      def comment
        @params[:create_synonym][:comment]
      end

      def concept_id
        @params[:concept_id]
      end

      def concept_label
        @params[:concept_label]
      end

      def curie
        @params[:curie]
      end

      def get_binding
        binding
      end

      def qualifier
        @params[:create_synonym][:qualifier]
      end

      def synonym_label
        @params[:create_synonym][:preferred_label]
      end

      def username
        @params[:username]
      end
    end
  end
end
