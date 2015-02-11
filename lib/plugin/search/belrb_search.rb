require_relative '../plugin'

module OpenBEL
  module Plugin

    class BELrbSearch
      include OpenBEL::Plugin

      ID   = 'belrb_search'
      NAME = 'BEL search using bel.rb'
      DESC = 'Search BEL identifiers using facilities in the bel.rb library.'

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
        require_relative '../../../lib/search/belrb_search.rb'
      end

      def create_instance
        OpenBEL::Search::BELrbSearch.new(@options)
      end
    end
  end
end
