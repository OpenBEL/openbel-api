require 'dot_hash'

module OpenBEL
  module Config
    include DotHash

    CFG_VAR = 'OPENBEL_API_CONFIG_FILE'

    def self.load!
      config_file = ENV[CFG_VAR] || raise('No OpenBEL API configuration found. Set the OPENBEL_API_CONFIG_FILE environment variable.')
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

      cfg
    end

    private

    def self.validate(cfg)
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
