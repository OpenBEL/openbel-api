module OpenBEL::Search
  module Search

    # Search BEL identifiers by +query_expression+.
    #
    # Control search results by the options:
    #
    # - +:type+:       one or more of the following +annotation_value, namespace_value+
    # = +:scheme_uri+: the concept scheme uri to search within (i.e. +http://www.openbel.org/bel/namespace/hgnc-human-genes+)
    #
    # @param query_expression    [responds to #to_s] query expression
    # @param options[type]       [Symbol]            type symbol
    # @param options[scheme_uri] [responds to #to_s] scheme uri
    # @return [Array<SearchResult>, nil]
    def search(query_expression, options = {})
      fail NotImplementedError.new, "#{__method__} is not implemented"
    end
  end
end
