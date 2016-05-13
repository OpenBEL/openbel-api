module OpenBEL
  module Nanopub
    module FacetAPI

      def create_facets(nanopub)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_facets_by_filters(filters = [])
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def remove_facets_by_filters(filters = [])
        fail NotImplementedError, "#{__method__} is not implemented"
      end
    end
  end
end
