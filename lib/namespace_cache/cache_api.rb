module OpenBEL
  module Namespace
    module CacheAPI

      def fetch_namespaces
        fail NotImplementedError
      end

      def fetch_namespace(namespace)
        fail NotImplementedError
      end

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
