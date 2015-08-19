require 'bel'

require_relative 'normalize_hash'
require_relative 'normalize_procedure'
require_relative 'namespace_value_quoting_transform'
require_relative 'normative_parameter_transform'
require_relative 'bel_serialization_transform'

module OpenBEL
  module Transform

    class NamespaceTransform

      def initialize(namespace_api)
        normalize_hash       = NormalizeHash.new(namespace_api)
        normalize_procedure  = NormalizeProcedure.new(normalize_hash)

        @parameter_transforms = [
          NamespaceValueQuotingTransform.new,
          NormativeParameterTransform.new(normalize_procedure)
        ]
      end

      def transform_evidence!(evidence)
        return unless evidence
        return unless evidence.bel_statement
        
        # parse BEL statement AST
        ast = BEL::Parser.parse(evidence.bel_statement)

        # apply parameter transformations to AST
        ast = ast.transform_tree(@parameter_transforms)

        # serialize BEL statement AST to BEL
        bel_serialization = BELSerializationTransform.new
        ast.transform_tree([bel_serialization])

        # assign normative statement to evidence
        evidence.bel_statement = bel_serialization.bel_string
      end
    end

  end
end
