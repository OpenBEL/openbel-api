module OpenBEL
  module Transform

    class NormalizeProcedure

      def initialize(normalize_hash)
        @normalize_hash = normalize_hash
      end

      def normative_namespace_value(namespace, value)
        @normalize_hash[
          [namespace, value, normative_namespace(namespace)]
        ]
      end

      private

      def normative_namespace(namespace)
        namespace.downcase!

        case namespace
        when 'egid', 'affx', 'hgnc', 'mgi', 'rgd', 'sp'
          'egid'
        when 'gobp', 'meshpp'
          'gobp'
        when 'do', 'meshd', 'sdis'
          'do'
        when 'chebi', 'meshc', 'schem'
          'chebi'
        else
          namespace
        end
      end
    end
  end
end
