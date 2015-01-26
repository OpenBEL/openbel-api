require_relative '../plugin'

module OpenBEL
  module Plugin

    class Evidence
      include OpenBEL::Plugin

      ID = 'evidence'
      NAME = 'OpenBEL Evidence API'
      DESC = 'API for accesing OpenBEL Evidence.'

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
        :evidence
      end

      def required_extensions
        []
      end

      def optional_extensions
        []
      end

      def on_load
        require_relative '../../evidence/mongo'
      end

      def validate(extensions = {}, options = {})
        puts "HI!!!"
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
        OpenBEL::Evidence::Evidence.new(@options)
      end
    end
  end
end
