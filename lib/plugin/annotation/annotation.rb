require_relative '../plugin'

module OpenBEL
  module Plugin

    class Annotation
      include OpenBEL::Plugin

      ID = 'annotation'
      NAME = 'OpenBEL Annotation API'
      DESC = 'API for accesing Annotation data for OpenBEL.'

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
        :annotation
      end

      def required_extensions
        [:storage, :search]
      end

      def optional_extensions
        []
      end

      def on_load
        require_relative '../../annotation/default'
      end

      def validate(extensions = {}, options = {})
        @storage_plugin = extensions.delete(:storage)
        if not @storage_plugin
          return ValidationError.new(self, :storage, "The storage extension is missing.")
        end
        @search_plugin  = extensions.delete(:search)
        if not @search_plugin
          return ValidationError.new(self, :search, "The search extension is missing.")
        end

        validation_successful
      end

      def configure(extensions = {}, options = {})
        @storage_plugin = extensions.delete(:storage)
        @search_plugin  = extensions.delete(:search)
        @options = options
      end

      def create_instance
        storage = @storage_plugin.create_instance
        search  = @search_plugin.create_instance
        OpenBEL::Annotation::Annotation.new(storage, search)
      end
    end
  end
end
