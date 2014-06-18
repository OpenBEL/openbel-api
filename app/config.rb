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
      cfg
    end

    def self.storage_rdf(cfg)
      return nil unless cfg.storage_rdf or cfg.storage_rdf.extension

      extension = cfg.storage_rdf.extension
      options = cfg.storage_rdf.options || {}
      require "storage_rdf/extensions/#{extension}"
      StorageRedland.new options
    end

    private

    def self.validate(cfg)
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
        options = cfg.storage_rdf.options || {}
        require "storage_rdf/extensions/#{extension}"
      rescue LoadError
        return [
          'storage_rdf.extension',
          "The #{extension} extension could not be loaded from storage_rdf/extensions/#{extension}."
        ]
      end
    end

    class SilentProperties < Properties
      def method_missing(key, *args, &block)
        return nil unless has_key?(key)
        execute(key, *args, &block)
      end
    end
  end
end
