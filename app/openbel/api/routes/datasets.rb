require 'bel'
require 'rdf'
require 'cgi'
require 'openbel/api/evidence/mongo'
require 'openbel/api/evidence/facet_filter'
require_relative '../resources/evidence_transform'

module OpenBEL
  module Routes

    class Datasets < Base
      include OpenBEL::Evidence::FacetFilter
      include OpenBEL::Resource::Evidence

      ACCEPTED_TYPES = {
        :bel  => 'application/bel',
        :xml  => 'application/xml',
        :xbel => 'application/xml',
        :json => 'application/json',
      }

      def initialize(app)
        super

        # TODO Remove this from config.yml; put in app-config.rb as an "evidence-store" component.
        @api = OpenBEL::Evidence::Evidence.new(
            :host     => 'localhost',
            :port     => 27017,
            :database => 'openbel'
        )

        # RdfRepository using Jena
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
            :tdb_directory => 'biological-concepts-rdf'
        )

        # Load RDF Monkeypatches.
        BEL::Translator.plugins[:rdf].create_translator

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
            evidence         = BEL.evidence(io, type).each.first
            void_dataset_uri = RDF::URI("#{base_url}/api/datasets/#{self.generate_uuid}")

            void_dataset = evidence.to_void_dataset(void_dataset_uri)
            unless void_dataset
              halt(
                  400,
                  { 'Content-Type' => 'application/json' },
                  render_json({ :status => 400, :msg => 'The dataset document does not contain a document header.' })
              )
            end

            identifier_statement = void_dataset.query(
                RDF::Statement.new(void_dataset_uri, RDF::DC.identifier, nil)
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

            datasets         = @rr.query_pattern(RDF::Statement.new(nil, RDF.type, RDF::VOID.Dataset))
            existing_dataset = datasets.find { |dataset_statement|
              @rr.has_statement?(
                  RDF::Statement.new(dataset_statement.subject, RDF::DC.identifier, identifier_statement.object)
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
            RDF::Statement.new(uri, RDF.type, RDF::VOID.Dataset)
          )
        end

        def retrieve_dataset(uri)
          dataset = {}
          identifier = @rr.query(
            RDF::Statement.new(uri, RDF::DC.identifier, nil)
          ).first
          dataset[:identifier] = identifier.object.to_s if identifier

          title = @rr.query(
            RDF::Statement.new(uri, RDF::DC.title, nil)
          ).first
          dataset[:title] = title.object.to_s if title

          description = @rr.query(
            RDF::Statement.new(uri, RDF::DC.description, nil)
          ).first
          dataset[:description] = description.object.to_s if description

          waiver = @rr.query(
            RDF::Statement.new(uri, RDF::URI('http://vocab.org/waiver/terms/waiver'), nil)
          ).first
          dataset[:waiver] = waiver.object.to_s if waiver

          creator = @rr.query(
            RDF::Statement.new(uri, RDF::DC.creator, nil)
          ).first
          dataset[:creator] = creator.object.to_s if creator

          license = @rr.query(
            RDF::Statement.new(uri, RDF::DC.license, nil)
          ).first
          dataset[:license] = license.object.to_s if license

          publisher = @rr.query(
            RDF::Statement.new(uri, RDF::DC.publisher, nil)
          ).first
          if publisher
            publisher.object
            contact_info = @rr.query(
              RDF::Statement.new(publisher.object, RDF::FOAF.mbox, nil)
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
        unless params['file']
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => "You must POST a 'file' parameter using multipart/form-data." })
          )
        end

        io, filename, type = params['file'].values_at(:tempfile, :filename, :type)
        unless ACCEPTED_TYPES.values.include?(type)
          type = mime_type(File.extname(filename))
        end

        halt 415 unless ACCEPTED_TYPES.values.include?(type)

        # Check dataset in request for suitability and conflict with existing resources.
        void_dataset_uri, void_dataset = check_dataset(io, type)

        # Create dataset in RDF.
        @rr.insert_statements(void_dataset)

        # Add slices of read evidence objects; save to Mongo and RDF.
        BEL.evidence(io, type).each.lazy.each_slice(500) do |slice|
          slice.map! do |ev|
            # Standardize annotations from experiment_context.
            @annotation_transform.transform_evidence!(ev, base_url)

            facets           = map_evidence_facets(ev)
            ev.bel_statement = ev.bel_statement.to_s
            hash             = ev.to_h
            hash[:facets]    = facets
            hash
          end

          _ids = @api.create_evidence(slice)

          dataset_parts = _ids.map { |object_id|
            RDF::Statement.new(void_dataset_uri, RDF::DC.hasPart, object_id.to_s)
          }
          @rr.insert_statements(dataset_parts)
        end

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
            :evidence_collection => {
              :type => 'evidence_collection',
              :href => "#{base_url}/api/datasets/#{id}/evidence"
            }
          }
        })
      end

      get '/api/datasets' do
        dataset_uris = @rr.query(
          RDF::Statement.new(nil, RDF.type, RDF::VOID.Dataset)
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
                :evidence_collection => {
                    :type => 'evidence_collection',
                    :href => "#{uri}/evidence"
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

        evidence_parts = @rr.query(
          RDF::Statement.new(void_dataset_uri, RDF::DC.hasPart, nil)
        )

        evidence_parts.each.lazy.each_slice(500) do |slice|
          slice.map! { |part_statement|
            part_statement.object.to_s
          }
          slice.compact!

          @api.delete_evidence(slice)
        end

        @rr.delete_statement(
          RDF::Statement.new(void_dataset_uri, nil, nil)
        )

        status 202
      end

      delete '/api/datasets' do
        datasets = @rr.query(
          RDF::Statement.new(nil, RDF.type, RDF::VOID.Dataset)
        ).map { |stmt|
          stmt.subject
        }.to_a
        halt 404 if datasets.empty?

        datasets.each do |void_dataset_uri|
          evidence_parts = @rr.query(
            RDF::Statement.new(void_dataset_uri, RDF::DC.hasPart, nil)
          )

          evidence_parts.each.lazy.each_slice(500) do |slice|
            slice.map! { |part_statement|
              part_statement.object.to_s
            }
            slice.compact!

            @api.delete_evidence(slice)
          end

          @rr.delete_statement(
            RDF::Statement.new(void_dataset_uri, nil, nil)
          )
        end

        status 202
      end

      private

      unless self.methods.include?(:generate_uuid)

        # Dynamically defines an efficient UUID method for the current ruby.
        if RUBY_ENGINE =~ /^jruby/i
          java_import 'java.util.UUID'
          define_method(:generate_uuid) do
            Java::JavaUtil::UUID.random_uuid.to_s
          end
        else
          require 'uuid'
          define_method(:generate_uuid) do
            UUID.generate
          end
        end
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
