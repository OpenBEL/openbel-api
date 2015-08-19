# Hash-like
module OpenBEL
  module Transform

    class NormalizeHash

      def initialize(namespace_api)
        @namespace_api = namespace_api
      end

      def [](key)
        namespace, value, normative_namespace = key

        if value.start_with?('"') && value.end_with?('"')
          value = value[1...-1]
        end
        equivalent = @namespace_api.find_equivalent(
          namespace,
          value,
          :target => normative_namespace
        )

        if !equivalent || equivalent.empty?
          nil
        else
          normalized_value = equivalent.first
          [
            @namespace_api.find_namespace(URI(normalized_value.inScheme)).prefix,
            normalized_value.identifier
          ]
        end
      end
    end

  end
end
