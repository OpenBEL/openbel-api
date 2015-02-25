require 'bel'
require 'cgi'
require 'lib/evidence/facet_filter'
require 'app/resources/evidence_transform'

module OpenBEL
  module Routes

    class Evidence < Base
      include OpenBEL::Evidence::FacetFilter
      include OpenBEL::Resource::Evidence

      def initialize(app)
        super
        @api = OpenBEL::Settings["evidence-api"].create_instance
        annotation_api = OpenBEL::Settings["annotation-api"].create_instance
        @annotation_transform = AnnotationTransform.new(annotation_api)
      end

      options '/api/evidence' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/evidence/:id' do
        response.headers['Allow'] = 'OPTIONS,GET,PUT,DELETE'
        status 200
      end

      post '/api/evidence' do
        validate_media_type! "application/json", :profile => schema_url('evidence')

        evidence_obj = read_json
        schema_validation = validate_schema(evidence_obj, :evidence)
        unless schema_validation[0]
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => schema_validation[1].join("\n") })
          )
        end

        # transformation
        evidence = evidence_obj['evidence']
        evidence = @annotation_transform.transform_evidence(evidence)
        evidence[:facets] = map_evidence_facets(evidence)

        _id = @api.create_evidence(evidence)

        status 201
        headers "Location" => "#{base_url}/api/evidence/#{_id}"
      end

      get '/api/evidence' do
        start    = (params[:start]  || 0).to_i
        size     = (params[:size]   || 0).to_i
        faceted  = as_bool(params[:faceted])

        filter_hash = {}
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = read_filter(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          filter_hash["#{filter['category']}.#{filter['name']}"] = filter['value']
        end

        fts_search_value = filter_hash.delete("fts.search")
        if fts_search_value
          filter_hash[:$text] = {
            :$search => fts_search_value
          }
        end

        results  = @api.find_evidence_by_query(filter_hash, start, size, faceted)
        evidence = results[:cursor].to_a
        facets   = results[:facets]

        halt 404 if evidence.empty?

        options = {
          :start   => start,
          :size    => size,
          :filters => filter_params
        }
        if facets
          facet_hashes = facets.map { |facet|
            filter = read_filter(facet['_id'])
            {
              :category => filter['category'].to_sym,
              :name     => filter['name'].to_sym,
              :value    => filter['value'],
              :filter   => facet['_id'],
              :count    => facet['count']
            }
          }
          options[:facets] = facet_hashes
        end

        render_collection(evidence, :evidence, options)
      end

      get '/api/evidence/:id' do
        evidence = @api.find_evidence_by_id(params[:id])
        halt 404 unless evidence
        # XXX Hack to return single resource wrapped as json array
        # XXX Need to better support evidence resource arrays in base.rb
        render(
          evidence,
          :evidence,
          :as_array => true
        )
      end

      put '/api/evidence/:id' do
        validate_media_type! "application/json", :profile => schema_url('evidence')

        id = params[:id]
        ev = @api.find_evidence_by_id(id)
        halt 404 unless ev

        evidence_obj = read_json
        schema_validation = validate_schema(evidence_obj, :evidence)
        unless schema_validation[0]
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => schema_validation[1].join("\n") })
          )
        end

        # transformation
        evidence = evidence_obj['evidence']
        evidence = @annotation_transform.transform_evidence(evidence)
        evidence[:facets] = map_evidence_facets(evidence)

        @api.update_evidence_by_id(id, evidence)

        status 202
      end

      delete '/api/evidence/:id' do
        id = params[:id]
        ev = @api.find_evidence_by_id(id)
        halt 404 unless ev

        @api.delete_evidence_by_id(id)
        status 202
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
