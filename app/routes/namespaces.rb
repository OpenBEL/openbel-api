require 'bel'
require 'cgi'
require 'multi_json'
require 'uri'

module OpenBEL
  module Routes

    # REST API for retrieving namespaces and values.  Provides the following capabilities:
    #
    # * Retrieve namespaces.
    # * Retrieve values for a namespace using the identifier, preferred name, or title.
    # * Retrieve equivalences for one or more values.
    # * Retrieve equivalences in a target namespace for one or more values.
    # * Retrieve orthologs for one or more values.
    # * Retrieve orthologs in a target namespace for one or more values.
    class Namespaces < Base

      RESULT_TYPES = {
        :resource => :all,
        :name => :prefLabel,
        :identifier => :identifier,
        :title => :title
      }

      def initialize(app)
        super

        # RdfRepository using Jena
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
          :tdb_directory => 'biological-concepts-rdf'
        )

        # Namespaces using RdfRepository
        @namespaces = BEL::Resource::Namespaces.new(@rr)

        # Resource Search
        @search     = BEL::Resource::Search.plugins[:sqlite].create_search(
          :database_file => 'biological-concepts-rdf.db'
        )
      end

      options '/api/namespaces' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/equivalents' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/namespaces/:namespace/orthologs' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/namespaces/:namespace/values/:value' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/values/:value/equivalents' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/values/:value/equivalents/:target' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/values/:value/orthologs' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/values/:value/orthologs/:target' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/namespaces' do
        namespaces = @namespaces.each.to_a

        halt 404 if not namespaces or namespaces.empty?

        render_collection(
          namespaces.sort { |x,y|
            x.prefLabel.to_s <=> y.prefLabel.to_s
          },
          :namespace
        )
      end

      get '/api/namespaces/values' do
        start    = (params[:start]  ||  0).to_i
        size     = (params[:size]   || -1).to_i
        size     = -1 if size <= 0
        faceted  = as_bool(params[:faceted])
        halt 501 if faceted

        filter_hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = read_filter(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          filter_hash[filter['category']][filter['name']] = filter['value']
        end

        halt 404 unless filter_hash['fts']['search'].is_a?(String)
        match = filter_hash['fts']['search']
        halt 404 unless match.length > 1

        match_results = @search.search(match, :namespace_concept, nil, nil,
          :start => start,
          :size => size
        ).map { |result|
          value = OpenBEL::Resource::Namespaces::NamespaceValueSearchResult.new(@rr, result.uri)
          value.match_text = result.snippet
          value
        }.to_a

        halt 404 if not match_results or match_results.empty?
        render_collection(
          match_results,
          :namespace_value,
          :adapter => Oat::Adapters::BasicJson
        )
      end

      get '/api/namespaces/:namespace' do |namespace|
        namespace = @namespaces.find(namespace).first

        halt 404 unless namespace

        status 200
        render_resource(
          namespace,
          :namespace
        )
      end

      get '/api/namespaces/:namespace/values' do |namespace|
        namespace = @namespaces.find(namespace).first
        halt 404 unless namespace

        start    = (params[:start]  ||  0).to_i
        size     = (params[:size]   || -1).to_i
        size     = -1 if size <= 0
        faceted  = as_bool(params[:faceted])
        halt 501 if faceted

        filter_hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = read_filter(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}
          filter_hash[filter['category']][filter['name']] = filter['value']
        end

        halt 404 unless filter_hash['fts']['search'].is_a?(String)
        match = filter_hash['fts']['search']
        halt 404 unless match.length > 1

        match_results = @search.search(match, :namespace_concept, namespace.uri.to_s, nil,
          :start => start,
          :size => size
        ).map { |result|
          value = OpenBEL::Resource::Namespaces::NamespaceValueSearchResult.new(@rr, result.uri)
          value.match_text = result.snippet
          value
        }.to_a

        halt 404 if not match_results or match_results.empty?
        render_collection(
          match_results,
          :namespace_value,
          :adapter => Oat::Adapters::BasicJson
        )
      end

      # TODO Requires a Namespace API to retrieve equivalents for matched values.
      # get '/api/namespaces/:namespace/equivalents' do |namespace|
      #   halt 400 unless request.params['value']

      #   values = CGI::parse(env["QUERY_STRING"])['value']
      #   options = {}
      #   if request.params['namespace']
      #     options[:target] = request.params['namespace']
      #   end

      #   if request.params['result']
      #     result = request.params['result'].to_sym
      #     halt 400 unless RESULT_TYPES.include? result
      #     options[:result] = RESULT_TYPES[result]
      #   end

      #   eq_mapping = @api.find_equivalents(namespace, values, options)
      #   halt 404 if eq_mapping.values.all? { |v| v == nil }
      #   response.headers['Content-Type'] = 'application/json'
      #   MultiJson.dump eq_mapping
      # end

      # TODO Requires a Namespace API to retrieve equivalents for matched values.
      # post '/api/namespaces/:namespace/equivalents' do |namespace|
      #   halt 400 unless request.media_type == 'application/x-www-form-urlencoded'

      #   content = request.body.read
      #   halt 400 if content.empty?

      #   params = Hash[
      #     URI.decode_www_form(content).group_by(&:first).map{
      #       |k,a| [k,a.map(&:last)]
      #     }
      #   ]

      #   halt 400 unless params['value']

      #   options = {}
      #   if params['namespace']
      #     options[:target] = params['namespace'].first
      #   end

      #   if params['result']
      #     result = params['result'].first.to_sym
      #     halt 400 unless RESULT_TYPES.include? result
      #     options[:result] = RESULT_TYPES[result]
      #   end

      #   eq_mapping = @api.find_equivalents(namespace, params['value'], options)
      #   response.headers['Content-Type'] = 'application/json'
      #   MultiJson.dump eq_mapping
      # end

      # TODO Requires a Namespace API to retrieve orthologs for matched values.
      # get '/api/namespaces/:namespace/orthologs' do |namespace|
      #   halt 400 unless request.params['value']

      #   values = CGI::parse(env["QUERY_STRING"])['value']
      #   options = {}
      #   if request.params['namespace']
      #     options[:target] = request.params['namespace']
      #   end

      #   if request.params['result']
      #     result = request.params['result'].to_sym
      #     halt 400 unless RESULT_TYPES.include? result
      #     options[:result] = RESULT_TYPES[result]
      #   end

      #   orth_mapping = @api.find_orthologs(namespace, values, options)
      #   halt 404 if orth_mapping.values.all? { |v| v == nil }
      #   response.headers['Content-Type'] = 'application/json'
      #   MultiJson.dump orth_mapping
      # end

      # TODO Requires a Namespace API to retrieve orthologs for matched values.
      # post '/api/namespaces/:namespace/orthologs' do |namespace|
      #   halt 400 unless request.media_type == 'application/x-www-form-urlencoded'

      #   content = request.body.read
      #   halt 400 if content.empty?

      #   params = Hash[
      #     URI.decode_www_form(content).group_by(&:first).map{
      #       |k,a| [k,a.map(&:last)]
      #     }
      #   ]

      #   halt 400 unless params['value']

      #   options = {}
      #   if params['namespace']
      #     options[:target] = params['namespace'].first
      #   end

      #   if params['result']
      #     result = params['result'].first.to_sym
      #     halt 400 unless RESULT_TYPES.include? result
      #     options[:result] = RESULT_TYPES[result]
      #   end

      #   orth_mapping = @api.find_orthologs(namespace, params['value'], options)
      #   response.headers['Content-Type'] = 'application/json'
      #   MultiJson.dump orth_mapping
      # end

      get '/api/namespaces/:namespace/values/:value' do |namespace, value|
        namespace = @namespaces.find(namespace).first
        halt 404 unless namespace

        value = namespace.find(value).first
        halt 404 unless value

        status 200
        render_resource(
          value,
          :namespace_value,
          :adapter => Oat::Adapters::BasicJson
        )
      end

      get '/api/namespaces/:namespace/values/:value/equivalents' do |namespace, value|
        namespace = @namespaces.find(namespace).first
        halt 404 unless namespace

        value = namespace.find(value).first
        halt 404 unless value

        equivalents = value.equivalents.to_a
        halt 404 if not equivalents or equivalents.empty?

        render_collection(
          equivalents,
          :namespace_value,
          :adapter => Oat::Adapters::BasicJson
        )
      end

      get '/api/namespaces/:namespace/values/:value/equivalents/:target' do |namespace, value, target|
        namespace = @namespaces.find(namespace).first
        halt 404 unless namespace
        halt 404 unless @namespaces.find(target).first

        value = namespace.find(value).first
        halt 404 unless value

        target_equivalents = value.equivalents(target).to_a
        halt 404 if not target_equivalents or target_equivalents.empty?

        render_collection(
          target_equivalents,
          :namespace_value,
          :adapter => Oat::Adapters::BasicJson
        )
      end

      get '/api/namespaces/:namespace/values/:value/orthologs' do |namespace, value|
        namespace = @namespaces.find(namespace).first
        halt 404 unless namespace

        value = namespace.find(value).first
        halt 404 unless value

        orthologs = value.orthologs.to_a
        halt 404 if not orthologs or orthologs.empty?

        render_collection(
          orthologs,
          :namespace_value,
          :adapter => Oat::Adapters::BasicJson
        )
      end

      get '/api/namespaces/:namespace/values/:value/orthologs/:target' do |namespace, value, target|
        namespace = @namespaces.find(namespace).first
        halt 404 unless namespace
        halt 404 unless @namespaces.find(target).first

        value = namespace.find(value).first
        halt 404 unless value

        target_orthologs = value.orthologs(target).to_a
        halt 404 if not target_orthologs or target_orthologs.empty?

        render_collection(
          target_orthologs,
          :namespace_value,
          :adapter => Oat::Adapters::BasicJson
        )
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
