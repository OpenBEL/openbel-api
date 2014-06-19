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
        if not config
          config = {}
        end
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

      if cfg.namespace
        ns_ext = cfg.namespace.extension
        require "namespace/extensions/#{ns_ext}"

        storage = self.make_storage(cfg.namespace)
        cache = self.make_cache(cfg.namespace)
        namespace_api = OpenBEL::Namespace::Namespace.new(:storage => storage, :cache => cache)

        cfg['namespace'] = true
        cfg['namespace_api'] = namespace_api
      else
        cfg['namespace'] = false
      end

      cfg
    end

    def self.make_storage(cfg)
      return nil unless cfg.storage or cfg.storage.extension

      extension = cfg.storage.extension
      options = cfg.storage.options || {}
      require "storage_rdf/extensions/#{extension}"
      OpenBEL::Storage.new options
    end

    def self.make_cache(cfg)
      return nil unless cfg.cache or cfg.cache.extension

      extension = cfg.cache.extension
      options = cfg.cache.options || {}
      require "namespace_cache/extensions/#{extension}"
      OpenBEL::Namespace::Cache.new options
    end

    private

    def self.validate(cfg)
      if cfg.namespace
        ncfg = cfg.namespace
        unless ncfg.extension
          return [
            'namespace',
            'An (extension) must be set in (namespace) configuration'
          ]
        end

        unless ncfg.storage or ncfg.cache
          return [
            'namespace',
            'The (namespace) configuration must define either storage or cache.'
          ]
        end

        if ncfg.cache
          unless ncfg.cache.extension
            return [
              'namespace.cache.extension',
              'An (extension) must be set in (namespace.cache) configuration'
            ]
          end

          begin
            extension = ncfg.cache.extension
            require "namespace_cache/extensions/#{extension}"
          rescue LoadError
            return [
              'namespace.cache.extension',
              "The #{extension} extension could not be loaded from namespace_cache/extensions/#{extension}."
            ]
          end
        else
          unless ncfg.storage.extension
            return [
              'namespace.storage.extension',
              'An (extension) must be set in (namespace.storage) configuration'
            ]
          end

          begin
            extension = ncfg.storage.extension
            require "storage_rdf/extensions/#{extension}"
          rescue LoadError
            return [
              'namespace.storage.extension',
              "The #{extension} extension could not be loaded from storage_rdf/extensions/#{extension}."
            ]
          end
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
