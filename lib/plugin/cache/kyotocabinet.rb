require 'pp'
require_relative '../plugin'

module OpenBEL
  module Plugin

    class CacheKyotoCabinet
      include OpenBEL::Plugin

      ID = 'kyotocabinet'
      NAME = 'KyotoCabinet Cache'
      DESC = 'Cache implementation using KyotoCabinet over FFI.'
      MEMR_TYPES = [ :"memory-hash" ]
      FILE_TYPES = [ :"file-hash" ]
      TYPE_OPTION_VALUES = [ MEMR_TYPES, FILE_TYPES ].flatten
      MODE_OPTION_VALUES = [ :reader, :writer, :create ]

      CREATE_MUTEX = Mutex.new

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
        :cache
      end

      def on_load
        require 'kyotocabinet'
      end

      def validate(extensions = {}, options = {})
        type = options.delete(:type)
        if not type
          return ValidationError.new(self, :type, "Option is missing. Options are one of [#{TYPE_OPTION_VALUES.join(', ')}].")
        end
        type = type.to_sym
        if not TYPE_OPTION_VALUES.include?(type)
          return ValidationError.new(self, :type, "Value not supported. Options are one of [#{TYPE_OPTION_VALUES.join(', ')}].")
        end

        mode = options.delete(:mode)
        if not mode
          return ValidationError.new(self, :mode, "Option is missing. Options are one of [#{MODE_OPTION_VALUES.join(', ')}].")
        end
        mode = mode.map { |v| v.to_s.to_sym }

        validation_successful
      end

      def configure(extensions = {}, options = {})
        @options = options
      end

      def create_instance
        CREATE_MUTEX.lock
        begin
          unless @instance
            type = @options[:type].to_sym
            mode = @options[:mode].map { |v| v.to_s.to_sym }

            @instance = case type
                        when :"memory-hash"
                          KyotoCabinet::Db::MemoryHash.new mode
                        when :"file-hash"
                          KyotoCabinet::Db::PolymorphicDb::tmp_filedb(KyotoCabinet::FILE_HASH)
                        end
          end
        ensure
          CREATE_MUTEX.unlock
        end

        @instance
      end
    end
  end
end
