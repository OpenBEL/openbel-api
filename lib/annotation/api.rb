module OpenBEL
  module Annotation

    module API

      def find_annotations(options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_annotation(annotation, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_annotation_value(annotation, value, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def search(match, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def search_annotation(annotation, match, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end
    end
  end
end
