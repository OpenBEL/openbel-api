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

      options '/api/annotations/values' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/annotations/:annotation' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/annotations/:annotation/values' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/annotations/:annotation/values/:value' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/annotations' do
        annotations = @api.find_annotations
        halt 404 if not annotations or annotations.empty?

        render_collection(
          annotations.sort { |x,y|
            x.prefLabel.to_s <=> y.prefLabel.to_s
          },
          :annotation
        )
      end

      get '/api/annotations/values' do
        start    = (params[:start]  ||  0).to_i
        size     = (params[:size]   || -1).to_i
        size     = -1 if size <= 0
        faceted  = as_bool(params[:faceted])
        halt 501 if faceted

        filter_hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = MultiJson.load(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          filter_hash[filter['category']][filter['name']] = filter['value']
        end

        halt 404 unless filter_hash['fts']['search'].is_a?(String)

        match = filter_hash['fts']['search']

        match_results = @api.search(match,
          :start => start,
          :size => size
        ).to_a

        halt 404 if not match_results or match_results.empty?
        render_collection(
          match_results,
          :annotation_value
        )
      end

      get '/api/annotations/:annotation' do |annotation|
        annotation = @api.find_annotation(annotation)
        halt 404 unless annotation

        status 200
        render_resource(annotation, :annotation)
      end

      get '/api/annotations/:annotation/values' do |annotation|
        annotation = @api.find_annotation(annotation)
        halt 404 unless annotation

        start    = (params[:start]  ||  0).to_i
        size     = (params[:size]   || -1).to_i
        size     = -1 if size <= 0

        faceted  = as_bool(params[:faceted])
        halt 501 if faceted

        filter_hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = MultiJson.load(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          filter_hash[filter['category']][filter['name']] = filter['value']
        end

        halt 404 unless filter_hash['fts']['search'].is_a?(String)

        match = filter_hash['fts']['search']

        match_results = @api.search_annotation(annotation, match,
          :start => start,
          :size => size
        ).to_a

        halt 404 if not match_results or match_results.empty?
        render_collection(
          match_results,
          :annotation_value
        )
      end

      get '/api/annotations/:annotation/values/:value' do |annotation, value|
        value = @api.find_annotation_value(annotation, value)
        halt 404 unless value

        status 200
        render_resource(value, :annotation_value)
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
