require_relative '../plugin_descriptor'

module OpenBEL
  module Plugin
    module Storage

      class StorageRedland
        include OpenBEL::PluginDescriptor

        ABBR = 'redland'
        NAME = 'Redland RDF Storage'
        DESC = 'Storage of RDF using the Redland libraries over FFI.'
        STORAGE_OPTION_VALUES = [ 'memory', 'sqlite' ]

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
          storage = options.delete(:storage)
          if not storage
            return ValidationError.new(self, :storage, "Option is missing. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}].")
          end
          if not STORAGE_OPTION_VALUES.include?(storage)
            return ValidationError.new(self, :storage, "Value is not supported. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}].")
          end

          name = options.delete(:storage)
          if not name and storage == :sqlite
            return ValidationError.new(self, :storage, "Option is required when using this storage option. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}].")
          end

          validation_successful
        end

        def configure(extensions = {}, options = {})
          @options = options
        end

        def on_load
          require_relative '../../../lib/storage/redland'
        end

        def create_instance
          OpenBEL::Storage::StorageRedland.new(@options)
        end
      end
    end
  end
end
