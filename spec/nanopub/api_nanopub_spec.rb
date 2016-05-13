require_relative '../spec_helper'
require 'json'

describe 'API Nanopub' do

  subject(:nanopub_api) {
    root_resource(:nanopub)
  }

  it 'returns 404 when the resource collection is empty' do
    response = api_conn.get '/api/nanopub'
    expect(response.status).to eql(404)
  end

  it 'returns an object when the resource collection is non-empty' do
    # create
    response = api_conn.post('/api/nanopub') { |req|
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.body                    = test_file('example_nanopub.json').read
    }
    expect(response.status).to eql(201)
    expect(response['Location']).not_to be_empty
    location = response['Location']

    expect(nanopub_api._resource._response.body).to         be_a(Hash)
    expect(nanopub_api._resource._response.body).to         include('nanopub_collection')
    expect(nanopub_api._resource['nanopub_collection']).to be_an(Array)

    # clean up
    api_conn.delete location
  end

  it 'instances can be retrieved by id' do
    # create
    response = api_conn.post('/api/nanopub') { |req|
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.body                    = test_file('example_nanopub.json').read
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
      # create nanopub resources
      nanopub_uris = 10.times.map do |_|
        response = api_conn.post('/api/nanopub') { |req|
          req.headers['Content-Type'] = 'application/json; charset=utf-8'
          req.body                    = test_file('example_nanopub.json').read
        }
        expect(response.status).to eql(201)
        expect(response['Location']).not_to be_empty
        response['Location']
      end

      nanopub_resource = api_conn.get { |req|
        req.url '/api/nanopub'
      }.body
      expect(nanopub_resource['nanopub_collection']).not_to be_nil
      expect(nanopub_resource['nanopub_collection'].size).to eql(10)
      expect(nanopub_resource['metadata']).not_to be_nil
      expect(nanopub_resource['metadata']['collection_paging']).not_to be_nil
      paging = nanopub_resource['metadata']['collection_paging']
      expect(paging['total']).to eql(10)
      expect(paging['total_filtered']).to eql(10)
      expect(paging['total_pages']).to eql(1)
      expect(paging['current_page']).to eql(1)
      expect(paging['current_page_size']).to eql(10)

      # clean up
      nanopub_uris.each { |uri|
        api_conn.delete uri
      }
    end
  end

  context 'filtered collection' do

    it 'reports collection paging' do
      # create nanopub resources
      human_nanopub = test_file('human_nanopub.json').read
      nanopub_uris = 10.times.map do |_|
        response = api_conn.post('/api/nanopub') { |req|
          req.headers['Content-Type'] = 'application/json; charset=utf-8'
          req.body                    = human_nanopub
        }
        expect(response.status).to eql(201)
        expect(response['Location']).not_to be_empty
        response['Location']
      end
      mouse_nanopub = test_file('mouse_nanopub.json').read
      nanopub_uris += 5.times.map do |_|
        response = api_conn.post('/api/nanopub') { |req|
          req.headers['Content-Type'] = 'application/json; charset=utf-8'
          req.body                    = mouse_nanopub
        }
        expect(response.status).to eql(201)
        expect(response['Location']).not_to be_empty
        response['Location']
      end

      nanopub_resource = api_conn.get { |req|
        req.url '/api/nanopub',
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
      expect(nanopub_resource['nanopub_collection']).not_to be_nil
      expect(nanopub_resource['nanopub_collection'].size).to eql(5)
      expect(nanopub_resource['metadata']).not_to be_nil
      expect(nanopub_resource['metadata']['collection_paging']).not_to be_nil
      paging = nanopub_resource['metadata']['collection_paging']
      expect(paging['total']).to eql(15)
      expect(paging['total_filtered']).to eql(10)
      expect(paging['total_pages']).to eql(2)
      expect(paging['current_page']).to eql(1)
      expect(paging['current_page_size']).to eql(5)

      # clean up
      nanopub_uris.each { |uri|
        api_conn.delete uri
      }
    end
  end
end
