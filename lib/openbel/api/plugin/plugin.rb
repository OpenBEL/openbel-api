module OpenBEL
  module Plugin

    EMPTY_ARRAY = [].freeze

    INCLUSION_MUTEX = Mutex.new
    private_constant :INCLUSION_MUTEX

    def self.included(base)
      INCLUSION_MUTEX.lock
      begin
        unless OpenBEL.const_defined?(:PluginClasses)
          OpenBEL.const_set(:PluginClasses, [])
        end
        OpenBEL::PluginClasses << base
      ensure
        INCLUSION_MUTEX.unlock
      end
    end

    def id
      fail NotImplementedError.new("#{__method__} not implemented")
    end

    def name
      fail NotImplementedError.new("#{__method__} not implemented")
    end

    def description
      fail NotImplementedError.new("#{__method__} not implemented")
    end

    def type
      fail NotImplementedError.new("#{__method__} not implemented.")
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

    def <=>(other)
      id_compare = id.to_s <=> other.to_s
      return id_compare unless id_compare == 0
      return self.name.to_s <=> other.name.to_s
    end

    def hash
      [id, name].hash
    end

    def ==(other)
      return false if other == nil
      return true if self.equal? other
      self.id == other.id && self.name == other.name
    end
    alias_method :eql?, :'=='

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
        "Error with #{field} field of #{plugin.id} (#{plugin.name}): #{error}"
      end
    end
  end
end
