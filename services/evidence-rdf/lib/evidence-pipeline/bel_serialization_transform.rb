module OpenBEL
  module Transform

    class BELSerializationTransform
      include BEL::LibBEL
      include BEL::Quoting

      attr_reader :bel_string

      def initialize
        @bel_string = ""
      end

      def call(ast_node)
        if ast_node.is_a?(BelAstNodeToken)
          case ast_node.token_type
          when :BEL_TOKEN_STATEMENT
          when :BEL_TOKEN_SUBJECT
          when :BEL_TOKEN_OBJECT
          when :BEL_TOKEN_REL
          when :BEL_TOKEN_TERM
          when :BEL_TOKEN_ARG
          when :BEL_TOKEN_NV
          end
        else
          case ast_node.value_type
          when :BEL_VALUE_FX
            function(ast_node.value)
          when :BEL_VALUE_REL
            relationship(ast_node.value)
          when :BEL_VALUE_PFX
            namespace_prefix(ast_node.value)
          when :BEL_VALUE_VAL
            namespace_value(ast_node.value)
          end
        end
      end

      def between(ast_node)
        if ast_node.is_a?(BelAstNodeToken)
          case ast_node.token_type
          when :BEL_TOKEN_STATEMENT
          when :BEL_TOKEN_SUBJECT
          when :BEL_TOKEN_OBJECT
          when :BEL_TOKEN_REL
          when :BEL_TOKEN_TERM
          when :BEL_TOKEN_ARG
            token_arg(ast_node)
          when :BEL_TOKEN_NV
          end
        end
      end

      def after(ast_node)
        if ast_node.is_a?(BelAstNodeToken)
          case ast_node.token_type
          when :BEL_TOKEN_STATEMENT
          when :BEL_TOKEN_SUBJECT
          when :BEL_TOKEN_OBJECT
          when :BEL_TOKEN_REL
          when :BEL_TOKEN_TERM
            @bel_string.concat(')')
          when :BEL_TOKEN_ARG
          when :BEL_TOKEN_NV
          end
        end
      end

      private

      def token_arg(ast_node)
        chained_arg_node = ast_node.right
        if !chained_arg_node.pointer.null?
          chained_arg_node = chained_arg_node.to_typed_node
          if !chained_arg_node.left.pointer.null? ||
             !chained_arg_node.right.pointer.null?
            @bel_string.concat(', ')
          end
        end
      end

      def function(fx)
        @bel_string.concat(fx).concat('(')
      end

      def relationship(rel)
        @bel_string.concat(" #{rel} ")
      end

      def namespace_prefix(prefix)
        return unless prefix
        @bel_string.concat(prefix).concat(':')
      end

      def namespace_value(value)
        @bel_string.concat(
          ensure_quotes(value)
        )
      end
    end

  end
end
