require 'bel'
require 'multi_json'
require 'cgi'
require 'lib/evidence/facet_filter'

module OpenBEL
  module Routes

    class Evidence < Base
      include OpenBEL::Evidence::FacetFilter

      PAGE_SIZES = 1..1000

      def initialize(app)
        super
        @api = OpenBEL::Settings["evidence-api"].create_instance
      end

      post '/api/evidence' do
        evidence_obj = read_json
        schema_validation = validate_schema(evidence_obj, :evidence)
        unless schema_validation[0]
          halt 400, schema_validation[1].join("\n")
        end

        evidence = evidence_obj['evidence']
        evidence[:facets] = map_evidence_facets(evidence)
        _id = @api.create_evidence(evidence)

        status 201
        headers "Link" => "#{base_url}/api/evidence/#{_id}"
      end

      get '/api/evidence' do
        offset = (params[:offset] || 0).to_i
        length = (params[:length]  || 100).to_i
        halt 400 unless PAGE_SIZES.include?(length)

        filter_hash = {}
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = MultiJson.load(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          filter_hash["#{filter['category']}.#{filter['name']}"] = filter['value']
        end

        evidence, facets = @api.find_evidence_by_query(filter_hash, offset, length)
        evidence_array = evidence.to_a

        halt 404 if evidence_array.empty?

        facet_objects = facets.map do |facet|
          filter = MultiJson.load(facet['_id'])
          {
            :category => filter['category'].to_sym,
            :name     => filter['name'].to_sym,
            :value    => filter['value'],
            :filter   => facet['_id'],
            :count    => facet['count']
          }
        end

        render(evidence_array, :evidence,
          :offset  => offset,
          :length  => length,
          :filters => filter_params,
          :facets  => facet_objects,
          :last    => (evidence_array.count < length)
        )
      end

      get '/api/evidence/:id' do
        evidence = @api.find_evidence_by_id(params[:id])
        halt 404 unless evidence
        render(evidence, :evidence)
      end

      put '/api/evidence/:id' do
        id = params[:id]
        ev = @api.find_evidence_by_id(id)
        halt 404 unless ev

        evidence_obj = read_json
        schema_validation = validate_schema(evidence_obj, :evidence)
        unless schema_validation[0]
          halt 400, schema_validation[1].join("\n")
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
