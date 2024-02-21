module RuboCop
  module Cop
    module Lint
      # Custom cop that checks for strings that are not localized.
      class NonLocalizedString < Cop
        MSG = 'String not localized: Use I18n for all user-visible strings.'.freeze

        def_node_matcher :plain_string?, <<~PATTERN
          (str _)
        PATTERN

        def on_str(node)
          return unless plain_string?(node)

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
