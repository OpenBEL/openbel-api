require 'bel'
require_relative 'search'

module OpenBEL
  module Search

    # TODO This will need to support RemoteAPI connector when it's ready.
    class BELrbSearch
      include Search

      def initialize(options = {})
        file = options[:file]
        @search = BEL::Search.use(:sqlite3, :db_file => file)
      end

      # see {OpenBEL::Search::Search#search}
      def search(query_expression, options = {})
        type       = options.delete(:type)
        scheme_uri = options.delete(:scheme_uri)

        query_expression = wildcard_pattern(query_expression)

        case type
        when :annotation_value
          @search.search_annotations(query_expression, scheme_uri, options)
        when :namespace_value
          @search.search_namespaces(query_expression, scheme_uri, options)
        else
          @search.search(query_expression, scheme_uri, options)
        end
      end

      private

      def wildcard_pattern(query_expression)
        query_expression.gsub(%r{([^\s]+)}, '*\1*')
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
