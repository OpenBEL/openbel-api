require 'bel'
require 'bel_parser'
require 'cgi'
require 'openbel/api/nanopub/mongo'
require 'openbel/api/nanopub/facet_filter'
require_relative '../resources/nanopub_transform'
require_relative '../helpers/nanopub'
require_relative '../helpers/filters'
require_relative '../helpers/pager'

module OpenBEL
  module Routes

    class Nanopubs < Base
      include OpenBEL::Nanopub::FacetFilter
      include OpenBEL::Resource::Nanopub
      include OpenBEL::Helpers
      include BELParser::Parsers

      def initialize(app)
        super

        bel_version = OpenBEL::Settings[:bel][:version]
        @spec       = BELParser::Language.specification(bel_version)

        mongo = OpenBEL::Settings[:nanopub_store][:mongo]
        @api  = OpenBEL::Nanopub::Nanopub.new(mongo)

        # RdfRepository using Jena.
        tdb = OpenBEL::Settings[:resource_rdf][:jena][:tdb_directory]
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(:tdb_directory => tdb)

        # Annotations and Namespaces using RdfRepository
        @annotations                   = BEL::Resource::Annotations.new(@rr)
        @namespaces                    = BEL::Resource::Namespaces.new(@rr)
        @annotation_transform          = AnnotationTransform.new(@annotations)
        @annotation_grouping_transform = AnnotationGroupingTransform.new
        @default_references            = {
          :annotations => @annotations.each.map { |an|
            prefix = an.prefix.first.capitalize

            {
              :keyword => prefix,
              :type    => :uri,
              :domain  => an.uri.to_s
            }
          },
          :namespaces  => @namespaces.each.map  { |ns|
            prefix = ns.prefix.first.upcase

            {
              :keyword => prefix,
              :type    => :uri,
              :domain  => ns.uri.to_s
            }
          }
        }

        @supported_namespaces = Hash[
          @namespaces.each.map { |ns|
            prefix = ns.prefix.first.upcase

            [
              prefix,
              BELParser::Expression::Model::Namespace.new(
                prefix,
                ns.uri
              )
            ]
          }
        ]
      end

      configure :development do |config|
        Nanopubs.reset!
        use Rack::Reloader
      end

      helpers do

        def stream_nanopub_objects(cursor)

          stream :keep_open do |response|
            cursor.each do |nanopub|
              nanopub.delete('facets')

              response << render_resource(
                  nanopub,
                  :nanopub,
                  :as_array => false,
                  :_id      => nanopub['_id'].to_s
              )
            end
          end
        end

        def stream_nanopub_array(cursor)
          stream :keep_open do |response|
            current = 0

            # determine true size of cursor given cursor limit/count
            if cursor.limit.zero?
              total = cursor.total
            else
              total = [cursor.limit, cursor.count].min
            end

            response << '['
            cursor.each do |nanopub|
              nanopub.delete('facets')

              response << render_resource(
                  nanopub,
                  :nanopub,
                  :as_array => false,
                  :_id      => nanopub['_id'].to_s
              )
              current += 1
              response << ',' if current < total
            end
            response << ']'
          end
        end

        def keys_to_s_deep(hash)
          hash.inject({}) do |new_hash, (key, value)|
            kstr           = key.to_s
            if value.kind_of?(Hash)
              new_hash[kstr] = keys_to_s_deep(value)
            elsif value.kind_of?(Array)
              new_hash[kstr] = value.map do |item|
                item.kind_of?(Hash) ?
                  keys_to_s_deep(item) :
                  item
              end
            else
              new_hash[kstr] = value
            end
            new_hash
          end
        end

        def validate_experiment_context(experiment_context)
          valid_annotations   = []
          invalid_annotations = []
          experiment_context.values.each do |annotation|
            name, value = annotation.values_at(:name, :value)
            found_annotation  = @annotations.find(name).first
            next unless found_annotation

            if found_annotation.find(value).first == nil
              invalid_annotations << annotation
            else
              valid_annotations << annotation
            end
          end

          [
            invalid_annotations.empty? ? :valid : :invalid,
            {
              :valid               => invalid_annotations.empty?,
              :valid_annotations   => valid_annotations,
              :invalid_annotations => invalid_annotations,
              :message             =>
                invalid_annotations
                  .map { |annotation|
                    name, value = annotation.values_at(:name, :value)
                    %Q{The value "#{value}" was not found in annotation "#{name}".}
                  }
                  .join("\n")
            }
          ]
        end

        def validate_statement(bel)
          filter =
            BELParser::ASTFilter.new(
              BELParser::ASTGenerator.new("#{bel}\n"),
              :simple_statement,
              :observed_term,
              :nested_statement
            )
          _, _, ast = filter.each.first

          if ast.nil? || ast.empty?
            return [
              :syntax_invalid,
              {
                valid_syntax:    false,
                valid_semantics: false,
                message:         'Invalid syntax.',
                warnings:        [],
                term_signatures: []
              }
            ]
          end

          message = ''
          terms   = ast.first.traverse.select { |node| node.type == :term }.to_a

          semantics_functions =
            BELParser::Language::Semantics.semantics_functions.reject { |fun|
              fun == BELParser::Language::Semantics::SignatureMapping
            }

          semantic_warnings =
            ast
              .first
              .traverse
              .flat_map { |node|
                semantics_functions.flat_map { |func|
                  func.map(node, @spec, @supported_namespaces)
                }
              }
              .compact

          if semantic_warnings.empty?
            valid = true
          else
            valid = false
            message =
              semantic_warnings.reduce('') { |msg, warning|
                msg << "#{warning}\n"
              }
            message << "\n"
          end

          urir      = BELParser::Resource.default_uri_reader
          urlr      = BELParser::Resource.default_url_reader
          validator = BELParser::Language::ExpressionValidator.new(@spec, @supported_namespaces, urir, urlr)
          term_semantics =
            terms.map { |term|
              term_result = validator.validate(term)
              valid      &= term_result.valid_semantics?
              bel_term    = serialize(term)

              unless valid
                message << "Term: #{bel_term}\n"
                term_result.invalid_signature_mappings.map { |m|
                  message << "  #{m}\n"
                }
                message << "\n"
              end

              {
                term:               bel_term,
                valid:              term_result.valid_semantics?,
                valid_signatures:   term_result.valid_signature_mappings.map(&:to_s),
                invalid_signatures: term_result.invalid_signature_mappings.map(&:to_s)
              }
            }

          [
            valid ? :valid : :semantics_invalid,
            {
              expression:      bel,
              valid_syntax:    true,
              valid_semantics: valid,
              message:         valid ? 'Valid semantics' : message,
              warnings:        semantic_warnings.map(&:to_s),
              term_signatures: term_semantics
            }
          ]
        end

        def validate_nanopub!(nanopub)
          stmt_result, stmt_validation     = validate_statement(nanopub.bel_statement)
          expctx_result, expctx_validation = validate_experiment_context(nanopub.experiment_context)

          return nil if stmt_result == :valid && expctx_result == :valid

          halt(
            422,
            {'Content-Type' => 'application/json'},
            render_json(
              {
                :nanopub_validation => {
                  :bel_statement_validation      => stmt_validation,
                  :experiment_context_validation => expctx_validation
                }
              }
            )
          )
        end
      end

      options '/api/nanopubs' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/nanopubs/:id' do
        response.headers['Allow'] = 'OPTIONS,GET,PUT,DELETE'
        status 200
      end

      post '/api/nanopubs' do
        # Validate BNJ.
        validate_media_type! "application/json"

        strict = as_bool(params[:strict]) || false

        nanopub_obj = read_json
        # STDERR.puts "DBG: nanopub_obj Variable config is #{nanopub_obj.inspect}"
        schema_validation = validate_schema(keys_to_s_deep(nanopub_obj), :nanopub)
        unless schema_validation[0]
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => schema_validation[1].join("\n") })
          )
        end

        nanopub_hash = nanopub_obj[:nanopub]
        if nanopub_hash[:references]
          nanopub_hash[:references] = {
            :annotations => nanopub_hash[:references][:annotations].map { |anno|
              {
                :keyword => anno[:keyword],
                :type    => :uri,
                :domain  => anno[:uri]
              }
            },
            :namespaces  => nanopub_hash[:references][:namespaces].map { |ns|
              {
                :keyword => ns[:keyword],
                :type    => :uri,
                :domain  => ns[:uri]
              }
            }
          }
        else
          nanopub_hash[:references] = @default_references
        end

        nanopub = ::BEL::Nanopub::Nanopub.create(nanopub_hash)

        # STDERR.puts "DBG: nanopub Variable config is #{nanopub.inspect}"

        # Standardize annotations.
        @annotation_transform.transform_nanopub!(nanopub, base_url)

        # Validate nanopub when strict is enabled.
        validate_nanopub!(nanopub) if strict

        # Build facets.
        facets = map_nanopub_facets(nanopub)
        hash = nanopub.to_h
        hash[:bel_statement] = hash.fetch(:bel_statement, nil).to_s

        # STDERR.puts "DBG: Variable config is #{hash.inspect}"

        hash[:facets]        = facets
        _id                  = @api.create_nanopub(hash)

        # Return Location information (201).
        status 201
        headers "Location" => "#{base_url}/api/nanopubs/#{_id}"
        headers "Content-Type" => 'application/json'
        render_json(
            {
                :status => 201,
                :location => "#{base_url}/api/nanopubs/#{_id}"
             }
        )
      end

			get '/api/nanopubs-stream', provides: 'application/json' do
        start                = (params[:start] || 0).to_i
        size                 = (params[:size]  || 0).to_i
        group_as_array       = as_bool(params[:group_as_array])

        filters = validate_filters!

        cursor  = @api.find_nanopub(filters, start, size, false)[:cursor]
        if group_as_array
          stream_nanopub_array(cursor)
        else
          stream_nanopub_objects(cursor)
        end
			end

      get '/api/nanopubs' do
        start                = (params[:start]  || 0).to_i
        size                 = (params[:size]   || 0).to_i
        faceted              = as_bool(params[:faceted])
        max_values_per_facet = (params[:max_values_per_facet] || -1).to_i

        filters = validate_filters!

        collection_total  = @api.count_nanopub()
        filtered_total    = @api.count_nanopub(filters)
        page_results      = @api.find_nanopub(filters, start, size, faceted, max_values_per_facet)

        render_nanopub_collection(
          'nanopub-export', page_results, start, size, filters,
          filtered_total, collection_total, @api
        )
      end

      get '/api/nanopubs/:id' do
        object_id = params[:id]
        halt 404 unless BSON::ObjectId.legal?(object_id)

        nanopub = @api.find_nanopub_by_id(object_id)
        halt 404 unless nanopub

        nanopub.delete('facets')

        # XXX Hack to return single resource wrapped as json array
        # XXX Need to better support nanopub resource arrays in base.rb
        render_resource(
          nanopub,
          :nanopub,
          :as_array => false,
          :_id      => object_id
        )
      end

      put '/api/nanopubs/:id' do
        object_id = params[:id]
        halt 404 unless BSON::ObjectId.legal?(object_id)

        validate_media_type! "application/json"

        strict = as_bool(params[:strict]) || false

        ev = @api.find_nanopub_by_id(object_id)
        halt 404 unless ev

        nanopub_obj = read_json
        schema_validation = validate_schema(keys_to_s_deep(nanopub_obj), :nanopub)
        unless schema_validation[0]
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => schema_validation[1].join("\n") })
          )
        end

        nanopub_hash = nanopub_obj[:nanopub]
        if nanopub_hash[:references]
          nanopub_hash[:references] = {
            :annotations => nanopub_hash[:references][:annotations].map { |anno|
              {
                :keyword => anno[:keyword],
                :type    => :uri,
                :domain  => anno[:uri]
              }
            },
            :namespaces  => nanopub_hash[:references][:namespaces].map { |ns|
              {
                :keyword => ns[:keyword],
                :type    => :uri,
                :domain  => ns[:uri]
              }
            }
          }
        else
          nanopub_hash[:references] = @default_references
        end

        # transformation
        nanopub  = ::BEL::Nanopub::Nanopub.create(nanopub_hash)
        @annotation_transform.transform_nanopub!(nanopub, base_url)

        # Validate nanopub when strict is enabled.
        validate_nanopub!(nanopub) if strict

        facets                  = map_nanopub_facets(nanopub)
        nanopub                 = nanopub.to_h
        nanopub[:bel_statement] = nanopub.fetch(:bel_statement, nil).to_s
        nanopub[:facets]        = facets

        @api.update_nanopub_by_id(object_id, nanopub)

        status 202
      end

      delete '/api/nanopubs/:id' do
        object_id = params[:id]
        halt 404 unless BSON::ObjectId.legal?(object_id)

        ev = @api.find_nanopub_by_id(object_id)
        halt 404 unless ev

        @api.delete_nanopub_by_id(object_id)
        status 202
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
