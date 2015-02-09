require 'bel'
require 'multi_json'
require 'cgi'
require 'lib/evidence/facet_filter'

module OpenBEL
  module Routes

    class Evidence < Base
      include OpenBEL::Evidence::FacetFilter

      def initialize(app)
        super
        @api = OpenBEL::Settings["evidence-api"].create_instance
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

        evidence = evidence_obj['evidence']
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
          filter = MultiJson.load(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          filter_hash["#{filter['category']}.#{filter['name']}"] = filter['value']
        end

        results  = @api.find_evidence_by_query(filter_hash, start, size, faceted)
        evidence = results[:cursor]
        facets   = results[:facets]

        halt 404 unless evidence.has_next?

        stream_resource_collection(:evidence, evidence, facets,
          :start   => start,
          :size    => size,
          :filters => filter_params,
          :facets  => facets
        )
        status 200
      end

      get '/api/evidence/:id' do
        evidence = @api.find_evidence_by_id(params[:id])
        halt 404 unless evidence
        render(
          [evidence],
          :evidence_resource
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

        evidence = evidence_obj['evidence']
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
