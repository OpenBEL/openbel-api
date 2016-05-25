require 'bel'
require 'bel/util'
require 'rdf'
require 'rdf/vocab'
require 'cgi'
require 'multi_json'
require 'openbel/api/nanopub/mongo'
require 'openbel/api/nanopub/facet_filter'
require 'openbel/api/helpers/uuid_generator'
require_relative '../resources/nanopub_transform'
require_relative '../helpers/nanopub'
require_relative '../helpers/filters'
require_relative '../helpers/pager'

module OpenBEL
  module Routes

    class Datasets < Base
      include OpenBEL::Nanopub::FacetFilter
      include OpenBEL::Resource::Nanopub
      include OpenBEL::Helpers
      include OpenBEL::Helpers::UUIDGenerator

      DEFAULT_TYPE = 'application/hal+json'
      ACCEPTED_TYPES = {
        :bel  => 'application/bel',
        :xml  => 'application/xml',
        :xbel => 'application/xml',
        :json => 'application/json',
      }

      MONGO_BATCH     = 500
      FACET_THRESHOLD = 10000
      DC              = ::RDF::Vocab::DC
      VOID            = ::RDF::Vocab::VOID
      FOAF            = ::RDF::Vocab::FOAF

      def initialize(app)
        super

        BEL.translator(:rdf)

        # nanopub API using Mongo.
        mongo = OpenBEL::Settings[:nanopub_store][:mongo]
        @api  = OpenBEL::Nanopub::Nanopub.new(mongo)

        # RdfRepository using Jena.
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
          :tdb_directory => OpenBEL::Settings[:resource_rdf][:jena][:tdb_directory]
        )

        # Annotations using RdfRepository
        annotations = BEL::Resource::Annotations.new(@rr)
        @annotation_transform = AnnotationTransform.new(annotations)
      end

      # Hang on to the Rack IO in order to do unbuffered reads.
      # use Rack::Config do |env|
      #   env['rack.input'], env['data.input'] = StringIO.new, env['rack.input']
      # end

      configure do
        ACCEPTED_TYPES.each do |ext, mime_type|
          mime_type(ext, mime_type)
        end
      end

      helpers do

        def check_dataset(io, type)
          begin
            nanopub         = BEL.nanopub(io, type).each.first

            unless nanopub
              halt(
                400,
                { 'Content-Type' => 'application/json' },
                render_json({ :status => 400, :msg => 'No BEL nanopub was provided. nanopub is required to infer dataset information.' })
              )
            end

            void_dataset_uri = RDF::URI("#{base_url}/api/datasets/#{generate_uuid}")

            void_dataset = nanopub.to_void_dataset(void_dataset_uri)
            unless void_dataset
              halt(
                  400,
                  { 'Content-Type' => 'application/json' },
                  render_json({ :status => 400, :msg => 'The dataset document does not contain a document header.' })
              )
            end

            identifier_statement = void_dataset.query(
                RDF::Statement.new(void_dataset_uri, DC.identifier, nil)
            ).to_a.first
            unless identifier_statement
              halt(
                  400,
                  { 'Content-Type' => 'application/json' },
                  render_json(
                    {
                      :status => 400,
                      :msg => 'The dataset document does not contain the Name or Version needed to build an identifier.'
                    }
                  )
              )
            end

            datasets         = @rr.query_pattern(RDF::Statement.new(nil, RDF.type, VOID.Dataset))
            existing_dataset = datasets.find { |dataset_statement|
              @rr.has_statement?(
                  RDF::Statement.new(dataset_statement.subject, DC.identifier, identifier_statement.object)
              )
            }

            if existing_dataset
              dataset_uri = existing_dataset.subject.to_s
              headers 'Location' => dataset_uri
              halt(
                  409,
                  { 'Content-Type' => 'application/json' },
                  render_json(
                      {
                          :status => 409,
                          :msg => %Q{The dataset document matches an existing dataset resource by identifier "#{identifier_statement.object}".},
                          :location => dataset_uri
                      }
                  )
              )
            end

            [void_dataset_uri, void_dataset]
          ensure
            io.rewind
          end
        end

        def dataset_exists?(uri)
          @rr.has_statement?(
            RDF::Statement.new(uri, RDF.type, VOID.Dataset)
          )
        end

        def retrieve_dataset(uri)
          dataset = {}
          identifier = @rr.query(
            RDF::Statement.new(uri, DC.identifier, nil)
          ).first
          dataset[:identifier] = identifier.object.to_s if identifier

          title = @rr.query(
            RDF::Statement.new(uri, DC.title, nil)
          ).first
          dataset[:title] = title.object.to_s if title

          description = @rr.query(
            RDF::Statement.new(uri, DC.description, nil)
          ).first
          dataset[:description] = description.object.to_s if description

          waiver = @rr.query(
            RDF::Statement.new(uri, RDF::URI('http://vocab.org/waiver/terms/waiver'), nil)
          ).first
          dataset[:waiver] = waiver.object.to_s if waiver

          creator = @rr.query(
            RDF::Statement.new(uri, DC.creator, nil)
          ).first
          dataset[:creator] = creator.object.to_s if creator

          license = @rr.query(
            RDF::Statement.new(uri, DC.license, nil)
          ).first
          dataset[:license] = license.object.to_s if license

          publisher = @rr.query(
            RDF::Statement.new(uri, DC.publisher, nil)
          ).first
          if publisher
            publisher.object
            contact_info = @rr.query(
              RDF::Statement.new(publisher.object, FOAF.mbox, nil)
            ).first
            dataset[:contact_info] = contact_info.object.to_s if contact_info
          end

          dataset
        end
      end

      options '/api/datasets' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/datasets/:id' do
        response.headers['Allow'] = 'OPTIONS,GET,PUT,DELETE'
        status 200
      end

      post '/api/datasets' do
        if request.media_type == 'multipart/form-data' && params['file']
          io, filename, type = params['file'].values_at(:tempfile, :filename, :type)
          unless ACCEPTED_TYPES.values.include?(type)
            type = mime_type(File.extname(filename))
          end

          halt(
            415,
            { 'Content-Type' => 'application/json' },
            render_json({
                          :status => 415,
                          :msg => %Q{
[Form data] Do not support content type for "#{type || filename}" when processing datasets from the "file" form parameter.
The following content types are allowed: #{ACCEPTED_TYPES.values.join(', ')}. The "file" form parameter type can also be inferred by the following file extensions: #{ACCEPTED_TYPES.keys.join(', ')}} })
          ) unless ACCEPTED_TYPES.values.include?(type)
        elsif ACCEPTED_TYPES.values.include?(request.media_type)
          type = request.media_type
          io   = request.body

          halt(
            415,
            { 'Content-Type' => 'application/json' },
            render_json({
                          :status => 415,
                          :msg => %Q{[POST data] Do not support content type #{type} when processing datasets. The following content types
are allowed in the "Content-Type" header: #{ACCEPTED_TYPES.values.join(', ')}} })
          ) unless ACCEPTED_TYPES.values.include?(type)
        else
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({
              :status => 400,
              :msg => %Q{Please POST data using a supported "Content-Type" or a "file" parameter using
the "multipart/form-data" content type. Allowed dataset content types are: #{ACCEPTED_TYPES.values.join(', ')}} })
          )
        end

        # Check dataset in request for suitability and conflict with existing resources.
        void_dataset_uri, void_dataset = check_dataset(io, type)

        # Create dataset in RDF.
        @rr.insert_statements(void_dataset)

        dataset    = retrieve_dataset(void_dataset_uri)
        dataset_id = dataset[:identifier]

        # Add batches of read nanopub objects; save to Mongo and RDF.
        # TODO Add JRuby note regarding Enumerator threading.
        nanopub_count = 0
        nanopub_batch = []

        # Clear out all facets before loading dataset.
        @api.delete_facets

        BEL.nanopub(io, type).each do |nanopub|
          # Standardize annotations from experiment_context.
          @annotation_transform.transform_nanopub!(nanopub, base_url)

          nanopub.metadata[:dataset] = dataset_id
          facets                     = map_nanopub_facets(nanopub)
          hash                       = BEL.object_convert(String, nanopub.to_h) { |str|
                                         str.gsub(/\n/, "\\n").gsub(/\r/, "\\r")
                                       }
          hash[:facets]              = facets
          # Create dataset field for efficient removal.
          hash[:_dataset]            = dataset_id
          hash[:bel_statement]       = hash[:bel_statement].to_s

          nanopub_batch << hash

          if nanopub_batch.size == MONGO_BATCH
            _ids = @api.create_nanopub(nanopub_batch)

            dataset_parts = _ids.map { |object_id|
              RDF::Statement.new(void_dataset_uri, DC.hasPart, object_id.to_s)
            }
            @rr.insert_statements(dataset_parts)

            nanopub_batch.clear

            # Clear out all facets after FACET_THRESHOLD nanopubs have been seen.
            nanopub_count += MONGO_BATCH
            if nanopub_count >= FACET_THRESHOLD
              @api.delete_facets
              nanopub_count = 0
            end
          end
        end

        unless nanopub_batch.empty?
          _ids = @api.create_nanopub(nanopub_batch)

          dataset_parts = _ids.map { |object_id|
            RDF::Statement.new(void_dataset_uri, DC.hasPart, object_id.to_s)
          }
          @rr.insert_statements(dataset_parts)

          nanopub_batch.clear
        end

        # Clear out all facets after the dataset is completely loaded.
        @api.delete_facets

        status 201
        headers 'Location' => void_dataset_uri.to_s
      end

      get '/api/datasets/:id' do
        id = params[:id]
        void_dataset_uri = RDF::URI("#{base_url}/api/datasets/#{id}")
        halt 404 unless dataset_exists?(void_dataset_uri)

        status 200
        render_json({
          :dataset => retrieve_dataset(void_dataset_uri),
          :_links => {
            :self => {
                :type => 'dataset',
                :href => void_dataset_uri.to_s
            },
            :nanopub_collection => {
              :type => 'nanopub_collection',
              :href => "#{base_url}/api/datasets/#{id}/nanopub"
            }
          }
        })
      end

      get '/api/datasets/:id/nanopub' do
        id = params[:id]
        void_dataset_uri = RDF::URI("#{base_url}/api/datasets/#{id}")
        halt 404 unless dataset_exists?(void_dataset_uri)

        dataset = retrieve_dataset(void_dataset_uri)

        start                = (params[:start]  || 0).to_i
        size                 = (params[:size]   || 0).to_i
        faceted              = as_bool(params[:faceted])
        max_values_per_facet = (params[:max_values_per_facet] || -1).to_i

        filters = validate_filters!

        collection_total  = @api.count_nanopub
        filtered_total    = @api.count_nanopub(filters)
        page_results      = @api.find_dataset_nanopub(dataset, filters, start, size, faceted, max_values_per_facet)
        name              = dataset[:identifier].gsub(/[^\w]/, '_')

        render_nanopub_collection(
          name, page_results, start, size, filters,
          filtered_total, collection_total, @api
        )
      end

      get '/api/datasets' do
        dataset_uris = @rr.query(
          RDF::Statement.new(nil, RDF.type, VOID.Dataset)
        ).map { |statement|
          statement.subject
        }.to_a
        halt 404 if dataset_uris.empty?

        dataset_collection = dataset_uris.map { |uri|
          {
            :dataset => retrieve_dataset(uri),
            :_links => {
                :self => {
                    :type => 'dataset',
                    :href => uri.to_s
                },
                :nanopub_collection => {
                    :type => 'nanopub_collection',
                    :href => "#{uri}/nanopub"
                }
            }
          }
        }

        status 200
        render_json({ :dataset_collection => dataset_collection })
      end

      delete '/api/datasets/:id' do
        id = params[:id]
        void_dataset_uri = RDF::URI("#{base_url}/api/datasets/#{id}")
        halt 404 unless dataset_exists?(void_dataset_uri)

        dataset = retrieve_dataset(void_dataset_uri)
        # XXX Removes all facets due to load of many nanopub.
        @api.delete_dataset(dataset[:identifier])
        @rr.delete_statement(RDF::Statement.new(void_dataset_uri, nil, nil))

        status 202
      end

      delete '/api/datasets' do
        datasets = @rr.query(
          RDF::Statement.new(nil, RDF.type, VOID.Dataset)
        ).map { |stmt|
          stmt.subject
        }.to_a
        halt 404 if datasets.empty?

        datasets.each do |void_dataset_uri|
          dataset = retrieve_dataset(void_dataset_uri)
          # XXX Removes all facets due to load of many nanopub.
          @api.delete_dataset(dataset[:identifier])
          @rr.delete_statement(RDF::Statement.new(void_dataset_uri, nil, nil))
        end

        status 202
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
