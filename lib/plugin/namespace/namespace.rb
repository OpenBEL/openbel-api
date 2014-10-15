require_relative '../plugin'

module OpenBEL
  module Plugin

    class Namespace
      include OpenBEL::Plugin

      ID = 'namespace'
      NAME = 'OpenBEL Namespace API'
      DESC = 'API for accesing Namespace data for OpenBEL.'

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
        :namespace
      end

      def required_extensions
        [:storage]
      end

      def optional_extensions
        []
      end

      def on_load
        require_relative '../../namespace/default'
      end

      def validate(extensions = {}, options = {})
        @storage_plugin = extensions.delete(:storage)
        if not @storage_plugin
          return ValidationError.new(self, :storage, "The storage extension is missing.")
        end
        validation_successful
      end

      def configure(extensions = {}, options = {})
        @storage_plugin = extensions.delete(:storage)
        @options = options
      end

      def create_instance
        OpenBEL::Namespace::Namespace.new(@storage_plugin.create_instance)
      end
    end
  end
end
