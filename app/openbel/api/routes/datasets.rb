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
      use Rack::Config do |env|
        env['rack.input'], env['data.input'] = StringIO.new, env['rack.input']
      end

      helpers do

        def check_dataset(io)
          begin
            evidence         = BEL.evidence(io, :bel).each.first
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

            void_dataset_uri
          ensure
            io.rewind
          end
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

      post '/api/dataset_mongo' do
        io = request.env['data.input']
        io.rewind

        s = Time.now
        count = 0
        BEL.evidence(io, :bel).each.lazy.each_slice(1000) do |slice|
          slice.map! do |ev|
            @annotation_transform.transform_evidence!(ev, base_url)

            facets           = map_evidence_facets(ev)
            ev.bel_statement = ev.bel_statement.to_s
            hash             = ev.to_h
            hash[:facets]    = facets
            hash
          end
          @api.create_evidence(slice)
          count += 1000

          puts "Saved #{count}"
        end
        e = Time.now
        puts "Saved to Mongo in #{e - s} seconds."

        status 201
        headers 'Location' => 'http://localhost:9000/api/datasets/1'
      end

      post '/api/datasets' do
        io = request.env['data.input']
        io.rewind

        void_dataset_uri = check_dataset(io)

        Tempfile.create('dataset_rdf') do |temp_file|
          s = Time.now
          BEL.translate(io, :bel, :rdf, temp_file, :void_dataset_uri => void_dataset_uri)
          e = Time.now
          puts "Converted to RDF, #{e - s} seconds."

          temp_file.rewind

          puts 'Load RDF'
          s = Time.now
          @rr.insert_reader(temp_file)
          e = Time.now
          puts "Loaded into evidence store, #{e - s} seconds."
        end

        status 201
        headers 'Location' => void_dataset_uri
      end

      get '/api/datasets' do
      end

      get '/api/datasets/:id' do
        id = params[:id]
      end

      put '/api/datasets/:id' do
        id = params[:id]
        status 202
      end

      delete '/api/datasets/:id' do
        id = params[:id]
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
