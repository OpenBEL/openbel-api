require 'bel'
require 'rdf'
require 'cgi'

module OpenBEL
  module Routes

    class Datasets < Base

      def initialize(app)
        super

        # # TODO Remove this from config.yml; put in app-config.rb as an "evidence-store" component.
        # @api = OpenBEL::Evidence::Evidence.new(
        #     :host     => 'localhost',
        #     :port     => 27017,
        #     :database => 'openbel'
        # )

        # RdfRepository using Jena
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
            :tdb_directory => 'biological-concepts-rdf'
        )

        # Annotations using RdfRepository
        # annotations = BEL::Resource::Annotations.new(@rr)

        # @annotation_transform = AnnotationTransform.new(annotations)
        # @annotation_grouping_transform = AnnotationGroupingTransform.new
      end

      # Hang on to the Rack IO in order to do unbuffered reads.
      use Rack::Config do |env|
        env['rack.input'], env['data.input'] = StringIO.new, env['rack.input']
      end

      helpers do
        def create_dataset(io)
          begin
            evidence        = BEL.evidence(io, :bel).each.first
            document_header = evidence.metadata[:document_header]
            if !document_header || !document_header.is_a?(Hash)
              halt 400
            end

            document_header            = Hash[document_header.map { |k,v| [k.to_s.downcase, v] }]
            name, version, description = document_header.values_at('name', 'version', 'description')
            if !name || !version
              halt 400
            end

            datasets         = @rr.query_pattern(RDF::Statement.new(nil, RDF.type, RDF::VOID.Dataset))
            existing_dataset = datasets.find { |dataset_statement|
              @rr.has_statement?(RDF::Statement.new(dataset_statement.subject, RDF::DC.identifier, "#{name}/#{version}"))
            }

            if existing_dataset
              headers 'Location' => existing_dataset.subject.to_s
              halt 409
            end

            dataset_uri = RDF::URI("#{base_url}/api/datasets/#{self.generate_uuid}")
            @rr.insert_statements(
              [
                  RDF::Statement.new(dataset_uri, RDF.type,            RDF::VOID.Dataset),
                  RDF::Statement.new(dataset_uri, RDF::DC.identifier,  "#{name}/#{version}"),
                  RDF::Statement.new(dataset_uri, RDF::DC.title,       name),
                  RDF::Statement.new(dataset_uri, RDF::DC.description, description || ''),
              ]
            )

            dataset_uri
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

      post '/api/datasets' do
        io = request.env['data.input']
        io.rewind

        dataset_uri = create_dataset(io)
        puts "Creating dataset '#{dataset_uri}'."

        Tempfile.create('dataset_rdf') do |temp_file|
          s = Time.now
          BEL.translate(io, :bel, :rdf, temp_file)
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
        headers 'Location' => dataset_uri
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
