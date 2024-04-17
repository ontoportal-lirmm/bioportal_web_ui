# frozen_string_literal: true

module KGCL
  module Renderers
    # Generate GitHub issue content for a node obsoletion change request. The change request is described using the
    # Knowledge Graph Change Language grammar, e.g.:
    #
    #   obsolete GO:0008150
    #
    # @see https://github.com/INCATools/kgcl KGCL documentation
    #
    class NodeObsoletionContent
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def render
        tr = KGCL::TemplateRenderer.new(
          title_template: 'node_obsoletion_title.erb',
          body_template: 'node_obsoletion_body.erb',
          bind_klass: self
        )
        tr.render
      end

      def comment
        @params[:node_obsoletion][:comment]
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

      def username
        @params[:username]
      end
    end
  end
end
