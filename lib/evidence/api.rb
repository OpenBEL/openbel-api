module OpenBEL
  module Evidence
    module API

      # single or array
      def create_evidence(evidence)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_evidence_by_id(id)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_evidence_by_query(query, offset = 0, length = 100, facet = false)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def update_evidence_by_id(id, evidence_update)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def update_evidence_by_query(query, evidence_update)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def delete_evidence_by_id(id)
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def delete_evidence_by_query(query)
        fail NotImplementedError, "#{__method__} is not implemented"
      end
    end
  end
end
