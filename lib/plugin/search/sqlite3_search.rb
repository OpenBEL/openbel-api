require_relative '../plugin'

module OpenBEL
  module Plugin

    class BELrbSearch
      include OpenBEL::Plugin

      ID   = 'sqlite3_search'
      NAME = 'Identifier search (SQLite3)'
      DESC = 'Search BEL identifiers using SQLite3 and FTS4.'

      def id
        ID
      end

      def name
        NAME
      end

      def description
        DESC
      end

      def type
        :search
      end

      def optional_extensions
        []
      end

      def validate(extensions = {}, options = {})
        file = options.delete(:file)
        unless file
          return ValidationError.new(self, :file, "Option is missing.")
        end

        if file and not File.readable?(file)
          return ValidationError.new(self, :file, "The 'file' option is not readable.")
        end

        validation_successful
      end

      def configure(extensions = {}, options = {})
        @options = options
      end

      def on_load
        require_relative '../../../lib/search/sqlite3.rb'
      end

      def create_instance
        OpenBEL::Search::Sqlite3FTS.new(@options)
      end
    end
  end
end
