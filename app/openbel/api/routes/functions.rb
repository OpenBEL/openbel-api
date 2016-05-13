require 'bel'
require 'bel_parser'

module OpenBEL
  module Routes

    class Functions < Base
      include BEL::Language

      def initialize(app)
        super
        bel_version = OpenBEL::Settings[:bel][:version]
        @spec       = BELParser::Language.specification(bel_version)
      end

      options '/api/language/functions' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/language/functions/:fx' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/language/functions' do
        render_collection(
          @spec.functions.sort_by(&:long),
          :function)
      end

      get '/api/language/functions/:fx' do
        function = @spec.function(params[:fx].to_sym)
        halt 404 unless function
        render_resource(function, :function)
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
