require_relative 'spec_helper'

describe 'Authentication capabilities' do
  it 'indicates whether authentication is enabled' do
    response = api_conn.get '/api/authentication-enabled'
    expect(response.status).to         eql(HTTP_OK)
    expect(response[:content_type]).to eql('application/json')
    enabled = JSON.parse(response.body)
    expect([true, false].include? enabled['enabled']).to eql(true)
  end
end

