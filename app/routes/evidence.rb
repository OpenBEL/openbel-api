require 'bel'
require 'multi_json'
require 'cgi'

module OpenBEL
  module Routes

    class Evidence < Base

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

        _id = @api.create_evidence(evidence_obj['evidence'])
        status 201
        headers "Link" => "#{base_url}/api/evidence/#{_id}"
      end

      get '/api/evidence' do
        offset = (params[:offset] || 0).to_i
        length = (params[:length]  || 100).to_i
        halt 400 unless PAGE_SIZES.include?(length)

        filter_hash = {}
        CGI::parse(env["QUERY_STRING"])['filter'].each do |filter|
          puts filter
          filter = MultiJson.load(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          category = filter['category']
          if category == 'context'
              category = 'biological_context'
          end
          filter_hash["#{category}.#{filter['name']}"] = filter['value']
        end

        puts filter_hash
        evidence, facets = @api.find_evidence_by_query(filter_hash, offset, length)

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

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :evidence => evidence.map { |doc|
            doc.delete('_id')
            doc.delete('facets')
            doc.to_h
          },
          :facets => facet_objects
        })
      end

      get '/api/evidence/:id' do
        ev = @api.find_evidence_by_id(params[:id])
        halt 404 unless ev

        status 200
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump ev.to_h
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

        @api.update_evidence_by_id(id, evidence_obj['evidence'])
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
