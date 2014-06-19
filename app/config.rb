require 'dot_hash'

module OpenBEL
  module Config
    include DotHash

    CFG_VAR = 'OPENBEL_SERVER_CONFIG'
    DEFAULT = 'config.yml'

    def self.load!
      config_file = ENV[CFG_VAR] || DEFAULT
      config = {}
      File.open(config_file, 'r:UTF-8') do |cf|
        config = YAML::load(cf)
      end
      cfg = Settings.new config, SilentProperties

      failure = validate cfg
      if failure
        if block_given?
          yield failure[1]
        else
          fail "Configuration error: #{failure[1]}"
        end
      end

      cfg['storage_rdf'] = self.storage_rdf(cfg)
      cfg['namespace_cache'] = self.namespace_cache(cfg)
      cfg
    end

    def self.storage_rdf(cfg)
      return nil unless cfg.storage_rdf or cfg.storage_rdf.extension

      extension = cfg.storage_rdf.extension
      options = cfg.storage_rdf.options || {}
      require "storage_rdf/extensions/#{extension}"
      StorageRedland.new options
    end

    def self.namespace_cache(cfg)
      return nil unless cfg.namespace_cache or cfg.namespace_cache.extension
      extension = cfg.namespace_cache.extension
      options = cfg.namespace_cache.options || {}
      require "namespaces/extensions/#{extension}"
      OpenBEL::Namespace::CacheGDBM.new options
    end

    private

    def self.validate(cfg)
      # validate storage_rdf
      unless cfg.storage_rdf
        return [
          'storage_rdf',
          'The (storage_rdf) configuration must be defined.'
        ]
      end
      unless cfg.storage_rdf.extension
        return [
          'storage_rdf.extension',
          'An (extension) must be set in (storage_rdf) configuration'
        ]
      end

      begin
        extension = cfg.storage_rdf.extension
        require "storage_rdf/extensions/#{extension}"
      rescue LoadError
        return [
          'storage_rdf.extension',
          "The #{extension} extension could not be loaded from storage_rdf/extensions/#{extension}."
        ]
      end

      # validate namespace_cache
      if cfg.namespace_cache
        unless cfg.namespace_cache.extension
          return [
            'namespace_cache.extension',
            'An (extension) must be set in (namespace_cache) configuration'
          ]
        end

        begin
          extension = cfg.namespace_cache.extension
          require "namespaces/extensions/#{extension}"
        rescue LoadError
          return [
            'namespace_cache.extension',
            "The #{extension} extension could not be loaded from namespaces/extensions/#{extension}."
          ]
        end
      end

      nil
    end

    class SilentProperties < Properties
      def method_missing(key, *args, &block)
        return nil unless has_key?(key)
        execute(key, *args, &block)
      end
    end
  end
end
