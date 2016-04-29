require 'bel_parser'

module OpenBEL
  module Routes

    class Relationships < Base
      include BEL::Language

      def initialize(app)
        super
        bel_version = OpenBEL::Settings[:bel][:version]
        @spec       = BELParser::Language.specification(bel_version)
      end

      options '/api/relationships' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/relationships/:rel' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/relationships' do
        render_collection(
          @spec.relationships.sort_by(&:long),
          :relationship)
      end

      get '/api/relationships/:rel' do
        relationship = @spec.relationship(params[:rel].to_sym)
        halt 404 unless relationship
        render_resource(relationship, :relationship)
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
