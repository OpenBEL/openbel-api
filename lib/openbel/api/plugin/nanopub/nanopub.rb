require_relative '../plugin'

module OpenBEL
  module Plugin

    class Nanopub
      include OpenBEL::Plugin

      ID = 'nanopub'
      NAME = 'OpenBEL Nanopub API'
      DESC = 'API for accesing OpenBEL Nanopub.'

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
        :nanopub
      end

      def required_extensions
        []
      end

      def optional_extensions
        []
      end

      def on_load
        require_relative '../../nanopub/mongo'
      end

      def validate(extensions = {}, options = {})
        [:host, :port, :database].map { |setting|
          unless options[setting]
            ValidationError.new(self, :storage, "The #{setting} setting is missing.")
          end
        }.compact!
      end

      def configure(extensions = {}, options = {})
        @options = options
      end

      def create_instance
        OpenBEL::Nanopub::Nanopub.new(@options)
      end
    end
  end
end
