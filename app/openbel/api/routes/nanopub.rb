require 'bel'
require 'cgi'
require 'openbel/api/nanopub/mongo'
require 'openbel/api/nanopub/facet_filter'
require_relative '../resources/nanopub_transform'
require_relative '../helpers/nanopub'
require_relative '../helpers/filters'
require_relative '../helpers/pager'

module OpenBEL
  module Routes

    class Nanopub < Base
      include OpenBEL::Nanopub::FacetFilter
      include OpenBEL::Resource::Nanopub
      include OpenBEL::Helpers

      def initialize(app)
        super

        mongo = OpenBEL::Settings[:nanopub_store][:mongo]
        @api  = OpenBEL::Nanopub::Nanopub.new(mongo)

        # RdfRepository using Jena
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
          :tdb_directory => OpenBEL::Settings[:resource_rdf][:jena][:tdb_directory]
        )

        # Annotations using RdfRepository
        annotations                    = BEL::Resource::Annotations.new(@rr)
        @annotation_transform          = AnnotationTransform.new(annotations)
        @annotation_grouping_transform = AnnotationGroupingTransform.new
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
      end

      options '/api/nanopub' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/nanopub/:id' do
        response.headers['Allow'] = 'OPTIONS,GET,PUT,DELETE'
        status 200
      end

      post '/api/nanopub' do
        # Validate JSON Nanopub.
        validate_media_type! "application/json"
        nanopub_obj = read_json

        schema_validation = validate_schema(keys_to_s_deep(nanopub_obj), :nanopub)
        unless schema_validation[0]
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => schema_validation[1].join("\n") })
          )
        end

        nanopub = ::BEL::Nanopub::Nanopub.create(nanopub_obj[:nanopub])

        # Standardize annotations.
        @annotation_transform.transform_nanopub!(nanopub, base_url)

        # Build facets.
        facets = map_nanopub_facets(nanopub)
        hash = nanopub.to_h
        hash[:bel_statement] = hash.fetch(:bel_statement, nil).to_s
        hash[:facets]        = facets
        _id                  = @api.create_nanopub(hash)

        # Return Location information (201).
        status 201
        headers "Location" => "#{base_url}/api/nanopub/#{_id}"
      end

			get '/api/nanopub-stream', provides: 'application/json' do
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

      get '/api/nanopub' do
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

      get '/api/nanopub/:id' do
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

      put '/api/nanopub/:id' do
        object_id = params[:id]
        halt 404 unless BSON::ObjectId.legal?(object_id)

        validate_media_type! "application/json"

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

        # transformation
        nanopub = nanopub_obj[:nanopub]
        nanopub  = ::BEL::Nanopub::Nanopub.create(nanopub)
        @annotation_transform.transform_nanopub!(nanopub, base_url)

        facets                  = map_nanopub_facets(nanopub)
        nanopub                 = nanopub.to_h
        nanopub[:bel_statement] = nanopub.fetch(:bel_statement, nil).to_s
        nanopub[:facets]        = facets

        @api.update_nanopub_by_id(object_id, nanopub)

        status 202
      end

      delete '/api/nanopub/:id' do
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
