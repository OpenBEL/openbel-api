require_relative '../spec_helper'

describe 'API Evidence' do

  subject(:evidence_api) {
    root_resource(:evidence)
  }

  it 'returns 404 when the resource collection is empty' do
    response = api_conn.get '/api/evidence'
    expect(response.status).to eql(404)
  end

  it 'returns an array when the resource collection is non-empty' do
    # create
    response = api_conn.post('/api/evidence') { |req|
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.body                    = test_file('example_evidence.json').read
    }
    expect(response.status).to eql(201)
    expect(response['Location']).not_to be_empty
    location = response['Location']

    expect(evidence_api._resource['evidence']).to      be_an(Array)
    expect(evidence_api._resource['evidence'].size).to eql(1)

    # clean up
    api_conn.delete location
  end

  it 'instances can be retrieved by id' do
    # create
    response = api_conn.post('/api/evidence') { |req|
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.body                    = test_file('example_evidence.json').read
    }
    expect(response.status).to eql(201)
    expect(response['Location']).not_to be_empty
    location = response['Location']

    # retrieve
    response = api_conn.get location
    expect(response.status).to eql(200)
    expect(response['Content-Type']).to match HAL_REGEX

    # clean up
    api_conn.delete location
  end

  it 'is pageable' do
    # XXX Fix paging in /api/evidence; the "start" and "next" link rel
    # should be templatable.

    # create
    response = api_conn.post('/api/evidence') { |req|
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.body                    = test_file('example_evidence.json').read
    }
    expect(response.status).to eql(201)
    expect(response['Location']).not_to be_empty
    location = response['Location']

    evidence_resource = api_conn.get { |req|
      req.url '/api/evidence', :start => 0, :size => 1
    }.body
    
    expect(evidence_resource['evidence']).not_to be_nil
    expect(evidence_resource['evidence'].size).to eql(1)

    # clean up
    api_conn.delete location
  end
end
