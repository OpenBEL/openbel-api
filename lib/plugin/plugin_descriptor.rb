module OpenBEL
  module PluginDescriptor

    EMPTY_ARRAY = [].freeze

    def abbreviation
      fail NotImplementedError.new("#{__method__} not implemented")
    end

    def name
      fail NotImplementedError.new("#{__method__} not implemented")
    end

    def description
      fail NotImplementedError.new("#{__method__} not implemented")
    end

    def required_extensions
      []
    end

    def optional_extensions
      []
    end

    def validate(extensions = {}, options = {})
      validation_successful
    end

    def on_load; end

    def configure(extensions = {}, options = {}); end

    def create_instance; end

    def on_unload; end

    protected

    def validation_successful
      EMPTY_ARRAY
    end

    def mri?
      defined?(RUBY_DESCRIPTION) && (/^ruby/ =~ RUBY_DESCRIPTION)
    end

    def jruby?
      defined?(RUBY_PLATFORM) && ("java" == RUBY_PLATFORM)
    end

    def rubinius?
      defined?(RUBY_ENGINE) && ("rbx" == RUBY_ENGINE)
    end

    ValidationError = Struct.new(:plugin, :field, :error) do

      def to_s
        "Error with #{field} field of #{plugin.abbreviation} (#{plugin.name}): #{error}"
      end
    end
  end
end
