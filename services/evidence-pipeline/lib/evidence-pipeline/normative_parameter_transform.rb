module OpenBEL
  module Transform

    class NormativeParameterTransform
      include BEL::LibBEL

      def initialize(normalize_procedure)
        @normalize_procedure = normalize_procedure
      end

      def call(ast_node)
        if ast_node.is_a?(BelAstNodeToken) && ast_node.token_type == :BEL_TOKEN_NV

          # return if there is not any namespace prefix
          return if ast_node.left.to_typed_node.value == nil

          normative_value = @normalize_procedure.normative_namespace_value(
            ast_node.left.to_typed_node.value,
            ast_node.right.to_typed_node.value
          )

          if normative_value
            BEL::LibBEL::bel_free_ast_node(ast_node.left.pointer)
            ast_node.left  = BelAstNode.new(
              bel_new_ast_node_value(:BEL_VALUE_PFX, normative_value[0].upcase)
            )

            BEL::LibBEL::bel_free_ast_node(ast_node.right.pointer)
            ast_node.right = BelAstNode.new(
              bel_new_ast_node_value(:BEL_VALUE_VAL, normative_value[1])
            )
          end
        end
      end
    end

  end
end
