# frozen_string_literal: true

Dir[Rails.root.join('app', 'lib', 'kgcl', 'renderers', '*.rb')].sort.each { |file| require file }

module KGCL
  module IssueContentGenerator
    RENDERERS = {
      KGCL::Operations::NEW_SYNONYM => NewSynonymContent,
      KGCL::Operations::REMOVE_SYNONYM => RemoveSynonymContent
    }.freeze

    def self.call(params)
      operation = params[:operation]
      raise ArgumentError, "Invalid KGCL operation: #{operation}" unless RENDERERS.key?(operation)

      renderer = RENDERERS.fetch(operation)
      renderer.new(params).render
    end
  end
end
