require 'bel'

module OpenBEL
  module Helpers

    # Helpers for translator functionality based on user's requested media
    # type.
    module Translators

      # Patch {::Sinatra::Helpers::Stream} to respect the +puts+ and +write+
      # method. This is necessary because the RDF.rb writers will call theseon
      # the IO object (in this case {::Sinatra::Helpers::Stream}).
      class ::Sinatra::Helpers::Stream

        def puts(*args)
          self << (
            args.map { |string| "#{string.encode(Encoding::UTF_8)}\n" }.join
          )
        end

        def write(string)
          self << string.encode(Encoding::UTF_8)
        end

        # flush is a no-op; flushing is handled by sinatra/rack server
        def flush; end
      end

      # Find a bel.rb translator plugin by value. The value is commonly the
      # id, file extension, or media type associated with the translator
      # plugin.
      #
      # @param  [#to_s] value     used to look up translator plugin registered
      #        with bel.rb
      # @return [BEL::Translator] the translator instance; or +nil+ if one
      #         cannot be found
      def self.for(value)
        BEL.translator(symbolize_value(value))
      end

      def self.plugin_for(value)
        BEL::Translator::Plugins.for(symbolize_value(value))
      end

      def self.requested_translator_plugin(request, params)
        if params && params[:format]
          self.plugin_for(params[:format])
        else
          request.accept.map { |accept_entry|
            self.plugin_for(accept_entry)
          }.compact.first
        end
      end

      def self.requested_translator(request, params)
        if params && params[:format]
          self.for(params[:format])
        else
          request.accept.map { |accept_entry|
            self.for(accept_entry)
          }.compact.first
        end
      end

      def self.symbolize_value(value)
        value.to_s.to_sym
      end
      private_class_method :symbolize_value
    end
  end
end
