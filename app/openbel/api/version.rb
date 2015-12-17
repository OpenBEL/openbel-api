module OpenBEL

  # Captures the version of the OpenBEL API.
  module Version

    # The frozen version {String}. See {Object#freeze}.
    STRING              = File.read(
                            File.join(
                              File.expand_path(File.dirname(__FILE__)),
                              '..', '..','..',
                              'VERSION'
                            )
                          ).chomp.freeze

    # The frozen {Fixnum version numbers}. See {Object#freeze}.
    MAJOR, MINOR, PATCH = STRING.split('.').map(&:freeze)

    # The frozen {Array} of {Fixnum version numbers}. See {Object#freeze}.
    VERSION_NUMBERS     = [MAJOR, MINOR, PATCH].freeze

    # Add singleton methods to the metaclass of {OpenBEL::Version}.
    class << self

      # Return the frozen, semantic version {String} for the OpenBEL API.
      # @return [frozen String] the semantic version of the OpenBEL API
      def to_s
        STRING
      end
      alias :to_str :to_s

      # Return the frozen, semantic version number {Array} for the OpenBEL API.
      # @return [frozen Array] the semantic version numbers of the OpenBEL API
      def to_a
        VERSION_NUMBERS
      end
    end
  end
end
