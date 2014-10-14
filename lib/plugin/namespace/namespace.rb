require_relative '../plugin_descriptor'

module OpenBEL
  module Plugin
    module Namespace

      class Namespace
        include OpenBEL::PluginDescriptor

        ABBR = 'namespace'
        NAME = 'OpenBEL Namespace API'
        DESC = 'API for accesing Namespace data for OpenBEL.'

        def abbreviation
          ABBR
        end

        def name
          NAME
        end

        def description
          DESC
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
          @cache_plugin = extensions.delete(:cache)
          validation_successful
        end

        def configure(extensions = {}, options = {})
          @storage_plugin = extensions.delete(:storage)
          @cache_plugin = extensions.delete(:cache)
          @options = options
        end

        def create_instance
          if @cache_plugin
            fail NotImplementedError, "cache plugin not implemented yet."
          else
            OpenBEL::Namespace::Namespace.new(@storage_plugin.create_instance)
          end
        end
      end
    end
  end
end
