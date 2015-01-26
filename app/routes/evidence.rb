require 'bel'

module OpenBEL
  module Routes

    class Evidence < Base

      def initialize(app)
        super
        @api = OpenBEL::Settings["evidence-api"].create_instance
      end

      post '/api/evidence' do
        evidence = read_json
        schema_validation = validate_schema(evidence, :evidence)
        unless schema_validation[0]
          halt 400, schema_validation[1].join("\n")
        end

        _id = @api.create_evidence(evidence)
        status 201
        headers "Link" => "#{base_url}/api/evidence/#{_id}"
      end

      get '/api/evidence' do
      end

      get '/api/evidence/:id' do
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
