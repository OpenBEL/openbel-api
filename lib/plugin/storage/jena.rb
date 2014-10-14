require_relative '../plugin_descriptor'

module OpenBEL
  module Plugin
    module Storage

      class StorageJena
        include OpenBEL::PluginDescriptor

        ABBR = 'jena'
        NAME = 'Apache Jena RDF Storage'
        DESC = 'Storage of RDF using the Apache Jena libraries.'

        def abbreviation
          ABBR
        end

        def name
          NAME
        end

        def description
          DESC
        end

        def validate(extensions = {}, options = {})
          if not jruby?
            return ValidationError.new(self, :plugin, "Option is only supported on the JRuby ruby engine.")
          end
          validation_successful
        end

        def configure(extensions = {}, options = {})
          @options = options
        end

        def on_load
        end

        def create_instance
        end
      end
    end
  end
end
