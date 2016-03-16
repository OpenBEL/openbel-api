module OpenBEL
  module Helpers

    DEFAULT_CONTENT_TYPE    = 'application/hal+json'
    DEFAULT_CONTENT_TYPE_ID = :hal

    def wants_default?
      if params[:format]
        return params[:format] == DEFAULT_CONTENT_TYPE
      end

      request.accept.any? { |accept_entry|
        accept_entry.to_s == DEFAULT_CONTENT_TYPE
      }
    end
  end
end
