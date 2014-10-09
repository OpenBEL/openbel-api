require_relative '../lib/plugin_descriptor'

module OpenBEL
  module Plugin
    module Cache

      class CacheKyotoCabinet
        include OpenBEL::PluginDescriptor

        ABBR = 'kyotocabinet'
        NAME = 'KyotoCabinet Cache'
        DESC = 'Cache implementation using KyotoCabinet over FFI.'
        MEMR_TYPES = [ :"memory-hash" ]
        FILE_TYPES = [ :"file-hash" ]
        TYPE_OPTION_VALUES = [ MEMR_TYPES, FILE_TYPES ].flatten
        MODE_OPTION_VALUES = [ :reader, :writer, :create ]

        def abbreviation
          ABBR
        end

        def name
          NAME
        end

        def description
          DESC
        end

        def on_load
          require_relative '../lib/cache/kyotocabinet'
        end

        def validate(options = {})
          type = options.delete(:type)
          if not type
            return ValidationError.new(self, :type, "Option is missing. Options are one of [#{TYPE_OPTION_VALUES.join(', ')}].")
          end
          if not TYPE_OPTION_VALUES.include?(type)
            return ValidationError.new(self, :type, "Value not supported. Options are one of [#{TYPE_OPTION_VALUES.join(', ')}].")
          end

          mode = options.delete(:mode)
          if not mode
            return ValidationError.new(self, :mode, "Option is missing. Options are one of [#{MODE_OPTION_VALUES.join(', ')}].")
          end

          file = options.delete(:file)
          if not file and FILE_TYPES.include?(type)
            return ValidationError.new(self, :mode, "Option is required for file database types.")
          end

          validation_successful
        end

        def create_instance(options = {})
          type = options.delete(:type)

          case type
          when :"memory-hash"
            KyotoCabinet::Db::MemoryHash.new mode
          when :"file-hash"
            KyotoCabinet::Db::FileHash.new file, mode
          end
        end
      end
    end
  end
end
