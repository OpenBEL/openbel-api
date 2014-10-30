require 'sqlite3'
require_relative 'fts_query'

module OpenBEL
  module FTS

    class SqliteFTS
      include FTSQuery

      def initialize(options = {})
        # TODO Set up sqlite db connection.
      end

      def find_matches(match_expression, options = {})
        # Issue fts query using prepared statement.
        # select * from literals_fts where literals_fts MATCH ?
        # TODO Prepare statement to save prep time
        # TODO Handle option to query for "snippet(text)"

        # XXX What do we return? How does it change if snippets is returned?
      end
    end
  end
end
