module OpenBEL
  module Helpers

    # Parse filter query parameters and partition into an {Array}. The first
    # index will contain the valid filters and the second index will contain
    # the invalid filters.
    #
    # @param [Array<String>] filter_query_params an array of filter strings
    #        encoded in JSON
    # @return [Array<Array<Hash>, Array<String>] the first index holds the
    #         valid, filter {Hash hashes}; the second index holds the invalid,
    #         filter {String strings}
    def parse_filters(filter_query_params)
      filter_query_params.map { |filter_string|
        begin
          MultiJson.load filter_string
        rescue MultiJson::ParseError => ex
          "#{ex} (filter: #{filter_string})"
        end
      }.partition { |filter|
        filter.is_a?(Hash)
      }
    end

    # Retrieve the filters that do not provide category, name, and value keys.
    #
    # The parsed, incomplete filters will contain an +:error+ key that provides
    # an error message intended for the user.
    #
    # @param [Array<Hash>] filters an array of filter {Hash hashes}
    # @return [Array<Hash>] an array of incomplete filter {Hash hashes} that
    #         contain a human-readable error at the +:error+ key
    def incomplete_filters(filters)
      filters.select { |filter|
        ['category', 'name', 'value'].any? { |f| !filter.include? f }
      }.map { |incomplete_filter|
        category, name, value = incomplete_filter.values_at('category', 'name', 'value')
        error = <<-MSG.gsub(/^\s+/, '').strip
          Incomplete filter, category:"#{category}", name:"#{name}", and value:"#{value}".
        MSG
        incomplete_filter.merge(:error => error)
      }
    end

    # Retrieve the filters that represent invalid full-text search values.
    #
    # The parsed, invalid full-text search filters will contain an +:error+ key
    # that provides an error message intended for the user.
    #
    # @param [Array<Hash>] filters an array of filter {Hash hashes}
    # @return [Array<Hash>] an array of invalid full-text search filter
    #         {Hash hashes} that contain a human-readable error at the
    #         +:error+ key
    def invalid_fts_filters(filters)
      filters.select { |filter|
        category, name, value = filter.values_at('category', 'name', 'value')
        category == 'fts' && name == 'search' && value.to_s.length <= 1
      }.map { |invalid_fts_filter|
        error = <<-MSG.gsub(/^\s+/, '').strip
          Full-text search filter values must be larger than one.
        MSG
        invalid_fts_filter.merge(:error => error)
      }
    end

    # Validate the requested filter query strings. If all filters are valid
    # then return them as {Hash hashes}, otherwise halt 400 Bad Request and
    # return JSON error response.
    def validate_filters!
      filter_query_params = CGI::parse(env["QUERY_STRING"])['filter']
      valid_filters, invalid_filters = parse_filters(filter_query_params)

      invalid_filters |= incomplete_filters(valid_filters)
      invalid_filters |= invalid_fts_filters(valid_filters)

      return valid_filters if invalid_filters.empty?

      halt(400, { 'Content-Type' => 'application/json' }, render_json({
        :status => 400,
        :msg => "Bad Request",
        :detail =>
          invalid_filters.
          map { |invalid_filter|
            if invalid_filter.is_a?(Hash) && invalid_filter[:error]
              invalid_filter[:error]
            else
              invalid_filter
            end
          }.
          map(&:to_s)
      }))
    end
  end
end
