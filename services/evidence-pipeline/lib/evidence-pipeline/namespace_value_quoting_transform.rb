module OpenBEL
  module Transform

    class NamespaceValueQuotingTransform
      include BEL::LibBEL
      include BEL::Quoting

      def call(ast_node)
        if ast_node.is_a?(BelAstNodeToken) && ast_node.token_type == :BEL_TOKEN_NV

          # return if there is not any namespace value
          namespace_value = ast_node.right.to_typed_node.value
          return unless namespace_value

          BEL::LibBEL::bel_free_ast_node(ast_node.right.pointer)
          ast_node.right = BelAstNode.new(
            bel_new_ast_node_value(:BEL_VALUE_VAL, remove_quotes(namespace_value))
          )
        end
      end
    end

  end
end
