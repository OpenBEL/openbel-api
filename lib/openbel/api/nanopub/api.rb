module OpenBEL
  module Nanopub
    module API

      # single or array
      def create_nanopub(nanopub)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_nanopub_by_id(id)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_nanopub(filters = [], offset = 0, length = 0, facet = false)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_all_namespace_references
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_all_annotation_references
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def count_nanopub(filters = [])
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def update_nanopub_by_id(id, nanopub_update)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def update_nanopub_by_query(query, nanopub_update)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def delete_nanopub_by_id(id)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def delete_nanopub_by_query(query)
        fail NotImplementedError, "#{__method__} is not implemented"
      end
    end
  end
end
