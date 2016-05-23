module OpenBEL
  module Helpers
    # Mixin to provide generation of String UUIDs.
    #
    # The {#generate_uuid} instance method is available with a
    # platform-specific implementation.
    module UUIDGenerator
      # Define UUID implementation based on Ruby.
      if RUBY_ENGINE =~ /^jruby/i
        java_import 'java.util.UUID'
        define_method(:generate_uuid) do
          Java::JavaUtil::UUID.random_uuid.to_s
        end
      else
        require 'uuid'
        define_method(:generate_uuid) do
          UUID.generate
        end
      end
    end
  end
end
