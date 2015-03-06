module OpenBEL
  module Search
    module IdentifierSearch

      # Search identifiers based on +query_expression+.
      #
      # Additional parameters
      #
      # +concept_type+:
      #   Searches on namespace values when set to +namespace_concept+.
      #   Searches on annotation values when set to +annotation_concept+.
      #   Otherwise, searches either namespace values or annotation values. This is the default.
      #
      # +scheme_uri+:
      #   Searches within a specific namespace or annotation identified by this URI.
      #   Otherwise, searches across all namespaces or annotations. This is the default.
      #
      # +species+:
      #   Searches for namespace values or annotation values represented within the provided species. Values from
      #   the NCBI Taxonomy are recognized (e.g. 9606, Homo sapiens, Human, etc.).
      #   Otherwise, searches across all values regardless of species.
      #
      # +options+:
      #   Options hash used to provide additional parameters to the search.
      #
      # @param query_expression [responds to #to_s] query expression
      # @param concept_type     [responds to #to_s] concept type
      # @param scheme_uri       [responds to #to_s] scheme uri
      # @param species          [responds to #to_s] species
      # @param options          [responds to #[]  ] options hash
      # @return [Array<SearchResult>, nil]
      def search(query_expression, concept_type = nil, scheme_uri = nil, species = nil, options = {})
        fail NotImplementedError.new, "#{__method__} is not implemented"
      end

      # Represents an identifier search result.
      #
      # @example Create with all parameters
      #   SearchResult.new(
      #     'viral <b>oncogene</b> homolog',
      #     'http://www.openbel.org/bel/namespace/hgnc-human-genes/391',
      #     'http://www.openbel.org/bel/namespace/hgnc-human-genes',
      #     '391',
      #     'AKT1',
      #     'v-akt murine thymoma viral oncogene homolog 1',
      #     ['AKT', 'PKB', 'PRKBA', 'RAC']
      #   )
      #
      # @example Create from hash
      #   SearchResult.new({ :pref_label => 'AKT1' })
      class SearchResult < Struct.new(:snippet, :uri, :scheme_uri, :identifier, :pref_label, :title, :alt_labels)
        def initialize(*args)
          if args.length == 1 && args.first.is_a?(Hash)
            hash = args.first
            super(*hash.values_at(*self.class.members))
          else
            super
          end
        end
      end
    end
  end
end

