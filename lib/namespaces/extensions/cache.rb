module OpenBEL
  module Namespace
    module Cache

      def fetch_all_values(namespace)
        fail NotImplementedError
      end

      def fetch_values(namespace, values)
        fail NotImplementedError
      end

      def fetch_equivalences(namespace, values)
        fail NotImplementedError
      end

      def fetch_equivalences(namespace, values, target_namespace)
        fail NotImplementedError
      end

      def fetch_orthologs(namespace, values)
        fail NotImplementedError
      end

      def fetch_orthologs(namespace, values, target_namespace)
        fail NotImplementedError
      end
    end
  end
end
