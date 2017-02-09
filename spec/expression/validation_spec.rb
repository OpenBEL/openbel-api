require_relative '../spec_helper'
require 'json'
require 'uri'

# Run this API specification against a running OpenBEL API REST endpoint.
#
# Set the API_ROOT_URL environment variable to the /api endpoint.
#
# Example:
#   API_ROOT_URL=http://localhost:9292/api rspec spec/expression/component_spec.rb
describe 'API Expression Validation' do

  context 'validation for parameter expression' do

    let(:example) {
      'HGNC:YFG'
    }

    it 'returns 400 when validating parameter expression (i.e. not a statement)' do
      response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
      expect(response.status).to eql(400)
    end

    it 'returns a validation JSON object' do
      response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
      expect(JSON.load(response.body)).to include('validation')
    end
  end

  context 'validation for incomplete expressions' do

    EXAMPLES =
      [
        'p(HGNC:AKT1) increases',
        'p(HGNC:AKT1) increases p()',
        'p()',
        'g(HGNC:AKT2) -> bp('
      ]

    EXAMPLES.each do |example|
      it "returns 400 status code indicating invalid syntax for example: #{example}" do
        response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
        expect(response.status).to eql(400)
      end

    end

    it 'returns a validation JSON object' do
      EXAMPLES.each do |example|
        response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
        expect(JSON.load(response.body)).to include('validation')
      end
    end
  end

  context 'validation for semantically-invalid expressions' do

    EXAMPLES =
      [
        'p(HGNC:AKT1, pmo(P))',
        'p(HGNC:YFG)',
        'g(X)',
        'p(HGNC:AKT1) => bp(Apoptosis)'
      ]

    EXAMPLES.each do |example|
      it "returns 422 status code indicating invalid semantics for example: #{example}" do
        response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
        expect(response.status).to eql(422)
      end
    end

    it 'returns a validation JSON object' do
      EXAMPLES.each do |example|
        response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
        expect(JSON.load(response.body)).to include('validation')
      end
    end
  end

  context 'validation for semantically-valid expressions' do

    EXAMPLES =
      [
        'p(HGNC:AKT1, pmod(DEFAULT:Phosphorylation))',
        'p(HGNC:AKT1)',
        'p(HGNC:AKT1) => bp(MESHPP:Apoptosis)',
        'p(HGNC:VHL) increases (p(HGNC:TNF) increases bp(GOBP:"cell death"))'
      ]

    EXAMPLES.each do |example|
      it "returns 200 status code indicating valid syntax and semantics for example: #{example}" do
        response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
        expect(response.status).to eql(200)
      end
    end

    it 'returns a validation JSON object' do
      EXAMPLES.each do |example|
        response = api_conn.get URI::encode("/api/expressions/#{example}/validation")
        expect(JSON.load(response.body)).to include('validation')
      end
    end
  end
end
