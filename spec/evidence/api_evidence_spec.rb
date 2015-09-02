require_relative '../spec_helper'
require 'json'

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

  context 'entire collection (10 resources)' do

    it 'reports collection paging' do
      # create evidence resources
      evidence_uris = 10.times.map do |_|
        response = api_conn.post('/api/evidence') { |req|
          req.headers['Content-Type'] = 'application/json; charset=utf-8'
          req.body                    = test_file('example_evidence.json').read
        }
        expect(response.status).to eql(201)
        expect(response['Location']).not_to be_empty
        response['Location']
      end

      evidence_resource = api_conn.get { |req|
        req.url '/api/evidence'
      }.body
      expect(evidence_resource['evidence']).not_to be_nil
      expect(evidence_resource['evidence'].size).to eql(10)
      expect(evidence_resource['metadata']).not_to be_nil
      expect(evidence_resource['metadata']['collection_paging']).not_to be_nil
      paging = evidence_resource['metadata']['collection_paging']
      expect(paging['total']).to eql(10)
      expect(paging['total_filtered']).to eql(10)
      expect(paging['total_pages']).to eql(1)
      expect(paging['current_page']).to eql(1)
      expect(paging['current_page_size']).to eql(10)

      # clean up
      evidence_uris.each { |uri|
        api_conn.delete uri
      }
    end
  end

  context 'filtered collection' do

    it 'reports collection paging' do
      # create evidence resources
      human_evidence = test_file('human_evidence.json').read
      evidence_uris = 10.times.map do |_|
        response = api_conn.post('/api/evidence') { |req|
          req.headers['Content-Type'] = 'application/json; charset=utf-8'
          req.body                    = human_evidence
        }
        expect(response.status).to eql(201)
        expect(response['Location']).not_to be_empty
        response['Location']
      end
      mouse_evidence = test_file('mouse_evidence.json').read
      evidence_uris += 5.times.map do |_|
        response = api_conn.post('/api/evidence') { |req|
          req.headers['Content-Type'] = 'application/json; charset=utf-8'
          req.body                    = mouse_evidence
        }
        expect(response.status).to eql(201)
        expect(response['Location']).not_to be_empty
        response['Location']
      end

      evidence_resource = api_conn.get { |req|
        req.url '/api/evidence',
          :start  => 0,
          :size   => 5,
          :filter => JSON.dump(
          {
            'category' => 'experiment_context',
            'name'     => 'Ncbi Taxonomy',
            'value'    => 'Homo sapiens'
          }
        )
      }.body
      expect(evidence_resource['evidence']).not_to be_nil
      expect(evidence_resource['evidence'].size).to eql(5)
      expect(evidence_resource['metadata']).not_to be_nil
      expect(evidence_resource['metadata']['collection_paging']).not_to be_nil
      paging = evidence_resource['metadata']['collection_paging']
      expect(paging['total']).to eql(15)
      expect(paging['total_filtered']).to eql(10)
      expect(paging['total_pages']).to eql(2)
      expect(paging['current_page']).to eql(1)
      expect(paging['current_page_size']).to eql(5)

      # clean up
      evidence_uris.each { |uri|
        api_conn.delete uri
      }
    end
  end
end
