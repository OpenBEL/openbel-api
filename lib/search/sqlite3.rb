require_relative 'identifier_search'
require_relative 'sqlite3_rank'
require 'erb'
require 'pathname'
require 'sqlite3'

module OpenBEL
  module Search

    class Sqlite3FTS
      include OpenBEL::Search::IdentifierSearch
      include OpenBEL::Search::Ranking

      QUERY_TEMPLATE = ERB.new(
        File.read(Pathname(File.dirname(__FILE__)) + 'sqlite3_template.erb'),
        nil,
        '>'
      )
      RANK_FUNCTION = 'rank_by_hits'
      PREPARED_STATEMENTS = {}

      def initialize(options = {})
        db_file = options[:file]
        if !db_file || !File.readable?(db_file)
          fail ArgumentError.new("The 'file' option cannot be read.")
        end

        @db = SQLite3::Database.new(db_file)
        @db.create_function(RANK_FUNCTION, 1) do |func, value|
          rank_by_hits(func, value)
        end
        @db.results_as_hash = true
      end

      # see {OpenBEL::IdentifierSearch#search}
      def search(query_expression, concept_type = nil, scheme_uri = nil, species = nil, options = {})
        start = (options.delete(:start) ||  0).to_i
        size  = options.delete(:size)   || -1
        if size.to_i.zero?
          fail ArgumentError.new(":size is zero")
        end

        options = {
          :match        => query_expression.encode('UTF-8'),
          :start        => start,
          :size         => size,
          :concept_type => (concept_type ? concept_type.to_s.encode('UTF-8') : nil),
          :scheme_uri   => (scheme_uri ? scheme_uri.to_s.encode('UTF-8') : nil),
          :species      => (species ? species.to_s.encode('UTF-8') : nil)
        }

        result_set = perform_query(options)
        if result_set.respond_to? :lazy
          result_set = result_set.lazy
        end
        result_set.map { |result_hash|
          symbolize_keys!(result_hash)
          result_hash[:alt_labels] = (result_hash[:alt_labels] || '').split('|')
          SearchResult.new(result_hash)
        }
      end

      private

      def perform_query(options = {})
        options.keep_if { |key, value| value != nil }
        stmt = PREPARED_STATEMENTS[options]
        if !stmt
          query = QUERY_TEMPLATE.result(binding)
          stmt = @db.prepare(query)
          PREPARED_STATEMENTS[options] = stmt
        end

        stmt.execute(options)
      end

      def symbolize_keys!(hash)
        hash.keys.each do |key|
            hash[(key.to_sym rescue key) || key] = hash.delete(key)
        end
      end
    end
  end
end
