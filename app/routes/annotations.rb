require 'bel'

module OpenBEL
  module Routes

    class Annotations < Base
      include BEL::Language

      SORTED_FUNCTIONS = FUNCTIONS.values.uniq.sort_by { |fx|
        fx[:short_form]
      }

      def initialize(app)
        super
        @api = OpenBEL::Settings["annotation-api"].create_instance
      end

      options '/api/annotations' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/annotations/:annotation' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/annotations/values/match-results/:match' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/annotations/:annotation/values/match-results/:match' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/annotations' do
        annotations = @api.find_annotations

        halt 404 if not annotations or annotations.empty?

        render(
          annotations.sort { |x,y|
            x.prefLabel.to_s <=> y.prefLabel.to_s
          },
          :annotation_collection
        )
      end

      get '/api/annotations/:annotation' do |annotation|
      end

      get '/api/annotations/values/match-results/:match' do |match|
      end

      get '/api/annotations/:annotation/values/match-results/:match' do |annotation, match|
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
