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

      get '/api/annotations/values/match-results/:match' do |match|
        start    = (params[:start]  || 0).to_i
        size     = (params[:size]   || 0).to_i

        faceted  = as_bool(params[:faceted])
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        halt 501 if faceted or not filter_params.empty?

        match_results = @api.search(match,
          :start => start,
          :size => size
        ).to_a

        halt 404 if not match_results or match_results.empty?
        render(
          match_results,
          :match_result_collection
        )
      end

      get '/api/annotations/:annotation' do |annotation|
        annotation = @api.find_annotation(annotation)

        halt 404 unless annotation

        status 200
        render(
          [annotation],
          :annotation
        )
      end

      get '/api/annotations/:annotation/values/match-results/:match' do |annotation, match|
        start    = (params[:start]  || 0).to_i
        size     = (params[:size]   || 0).to_i

        faceted  = as_bool(params[:faceted])
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        halt 501 if faceted or not filter_params.empty?

        match_results = @api.search_annotation(annotation, match,
          :start => start,
          :size => size
        ).to_a

        halt 404 if not match_results or match_results.empty?
        render(
          match_results,
          :match_result_collection
        )
      end

      get '/api/annotations/:annotation/values/:value' do |annotation, value|
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
