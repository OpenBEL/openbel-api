require 'tsort'

module OpenBEL
  module Helpers

    class DependencyGraph
      include TSort

      def initialize
        @hash = Hash.new { |hash, key| hash[key] = [] }
      end

      def [](key)
        @hash[key]
      end

      def add_dependency(first, *dependency_requirements)
        @hash[first] ||= []
        (dependency_requirements || []).flatten.each do |dep|
          _add_dependency(first, dep)
        end
        @hash[first]
      end

      def delete(key)
        @hash.delete(key)
      end

      def each_key(&block)
        @hash.each_key(&block)
      end

      def tsort_each_child(key, &block)
        @hash[key].each(&block)
      end

      def tsort_each_node(&block)
        @hash.each_key(&block)
      end

      private

      def _add_dependency(key1, key2)
        @hash[key1] << key2
        @hash[key2] = []
        key2
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
