require_relative '../spec_helper'
require 'uri'

# Run this API specification against a running OpenBEL API REST endpoint.
#
# Set the API_ROOT_URL environment variable to the /api endpoint.
#
# Example:
#   API_ROOT_URL=http://localhost:9292/api rspec spec/expression/component_spec.rb
describe 'API Expression Component' do

  [
    'AKT1',
    'p(SFAM:test',
    'p(SFAM:test) increases (HGNC:CDK1)',
    'p(SFAM:test) increases p(HGNC:CDK1'
  ].each do |example|
    it "returns 404 for syntactically-invalid example: #{example}" do
      response = api_conn.get URI::encode("/api/expressions/#{example}/components")
      expect(response.status).to eql(404)
    end
  end

  it 'returns 404 when smart quotes are contained in the expression' do
    example  = 'p(SFAM:”RAS Family”)'
    response = api_conn.get URI::encode("/api/expressions/#{example}/components")
    expect(response.status).to eql(404)
  end

  it 'returns 422 when relationship is invalid' do
    example  = 'p(SFAM:"RAS Familiy") increses p(HGNC:CDK1)'
    response = api_conn.get URI::encode("/api/expressions/#{example}/components")
    expect(response.status).to eql(422)
  end

  [
    'p(HGNC:YFG)',
    'p(HGNC:YFG) -> p(SFAM:"RAS Family")'
  ].each do |example|
    it "returns 200 for syntactically-valid example: #{example}" do
      response = api_conn.get URI::encode("/api/expressions/#{example}/components")
      expect(response.status).to eql(200)
    end
  end
end
