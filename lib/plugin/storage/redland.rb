require_relative '../plugin'

module OpenBEL
  module Plugin

    class StorageRedland
      include OpenBEL::Plugin

      ID = 'redland'
      NAME = 'Redland RDF Storage'
      DESC = 'Storage of RDF using the Redland libraries over FFI.'
      STORAGE_OPTION_VALUES = [ 'memory', 'sqlite' ]

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
        :storage
      end

      def optional_extensions
        [:cache]
      end

      def validate(extensions = {}, options = {})
        storage = options.delete(:storage)
        if not storage
          return ValidationError.new(self, :storage, "Option is missing. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}].")
        end
        if not STORAGE_OPTION_VALUES.include?(storage)
          return ValidationError.new(self, :storage, "Value is not supported. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}].")
        end

        name = options.delete(:name)
        if not name and storage == :sqlite
          return ValidationError.new(self, :storage, "Option is required when using this storage option. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}].")
        end

        validation_successful
      end

      def configure(extensions = {}, options = {})
        @cache_plugin = extensions[:cache]
        @options = options
      end

      def on_load
        require_relative '../../../lib/storage/redland'
        require_relative '../../../lib/storage/cache_proxy'
      end

      def create_instance
        storage = OpenBEL::Storage::StorageRedland.new(@options)

        if @cache_plugin
          cache = @cache_plugin.create_instance
          OpenBEL::Storage::CacheProxy.new(storage, cache)
        else
          storage
        end
      end
    end
  end
end
