require 'bel'
require 'multi_json'

module OpenBEL
  module Routes

    class Evidence < Base

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
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
