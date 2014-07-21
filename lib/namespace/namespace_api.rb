module OpenBEL
  module Namespace
    module NamespaceAPI

      def find_namespaces(options = {})
        fail NotImplementedError
      end

      def find_namespace(namespace, options = {})
        fail NotImplementedError
      end

      def find_namespace_value(namespace, value, options = {})
        fail NotImplementedError
      end

      def find_namespace_values(namespace, options = {}, &block)
        fail NotImplementedError
      end

      def find_equivalent(namespace, value, options = {})
        fail NotImplementedError
      end

      def find_equivalents(namespace, values, options = {})
        fail NotImplementedError
      end

      def find_ortholog(namespace, value, options = {})
        fail NotImplementedError
      end

      def find_orthologs(namespace, value, options = {})
        fail NotImplementedError
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
