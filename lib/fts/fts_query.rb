module OpenBEL
  module FTS
    module FTSQuery

      def find_matches(match_expression, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end
    end
  end
end
