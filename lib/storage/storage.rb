module OpenBEL
  module Storage

    def describe(subject, &block)
      fail NotImplementedError
    end

    def statements(pattern, &block)
      fail NotImplementedError
    end
  end
end
# vim: ts=2 sw=2
