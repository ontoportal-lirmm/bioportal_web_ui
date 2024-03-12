# frozen_string_literal: true

# Detects every text that is not an argument or the value of a Hash.
# These where excluded because there is no way to differentiate between
# class: 'bold red' and data: { confirm: 'are you sure?' }.
# Howerver, detects most cases correctly with almost no false positives
module HamlLint
    # Linter for detecting plain text in HAML
    class Linter::NoPlainTextLinter < Linter
        HTML_SPECIAL = /&\w*\;/.freeze
        ALPHABETIC = /.*[a-zA-Z].*$/.freeze
        puts "hello"
        include LinterRegistry
  
        def visit_tag(node)
          return check_script(node) if node.script.length.positive?
  
          check_tag_value(node)
        end
  
        def visit_plain(node)
          return unless alphabetic?(node.text.strip) &&
                        !special_html?(node.text.strip)
  
          record(node, node.text.strip)
        end
  
        def visit_script(node)
          check_script(node)
        end
  
        private
  
        def check_script(node)
          syntax_tree = node.parsed_script.syntax_tree
          return unless syntax_tree
  
          check_node(node, syntax_tree) ||
            syntax_tree.each_descendant.any? do |sub_node|
              check_node(node, sub_node)
            end
        end
  
        def check_tag_value(node)
          value = value_for_node(node)
          return unless alphabetic?(value)
  
          record(node, value)
        end
  
        def value_for_node(node)
          node.instance_variable_get(:@value)[:value]
        end
  
        def check_node(lint_node, ast_node)
          return unless string_literal?(ast_node)
  
          record(lint_node, ast_node.source)
        end
  
        def string_literal?(node)
          string?(node) && !arg?(node) && !special_html?(node.source)
        end
  
        def string?(node)
          node.send(:str_type?) && alphabetic?(node.source)
        end
  
        def alphabetic?(string)
          ALPHABETIC =~ string
        end
  
        def special_html?(string)
          HTML_SPECIAL =~ string
        end
  
        def arg?(node)
          node.parent&.send_type? || node.parent&.pair_type?
        end
  
        def record(node, string)
          record_lint(node, message(string))
        end
  
        def message(string)
          "`#{string}` should be translated or in a helper"
        end
    end
end