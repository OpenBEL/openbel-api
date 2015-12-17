require_relative 'spec_helper'

describe 'API Spec' do

  subject(:api) {
    Hyperclient.new(api_root)
  }

  it 'return a HAL API description' do
    expect(api._response.status).to         eql(HTTP_OK)
    expect(api._response[:content_type]).to eql(HAL)
  end

  it 'does not contain embedded entities' do
    expect(api._embedded.to_a).to be_empty
  end

  it 'does contain links' do
    expect(api._links.to_a).not_to be_empty
  end

  it 'links use the item IANA link relation' do
    expect(api._links.to_h.keys).to eql(['item'])
  end

  it 'can navigate to "evidence" resource' do
    evidence_link = api._links.item.find { |item|
      item._url =~ %r{/evidence$}
    }
    expect(evidence_link._options._response.status).to  eq(HTTP_OK)
    expect(evidence_link._options._response[:allow]).to eq('OPTIONS,POST,GET')
  end
end
