module OpenBEL::Cache
  module Cache

    def [](key)
      read(key)
    end

    def []=(key, value)
      write(key, value)
    end

    def clear
      purge
    end

    protected

    def read(key)
      fail NotImplementedError.new, "#{__method__} is not implemented"
    end

    def write(key, value)
      fail NotImplementedError.new, "#{__method__} is not implemented"
    end

    def purge
      fail NotImplementedError.new, "#{__method__} is not implemented"
    end
  end
end
