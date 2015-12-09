require 'bel'
require 'cgi'
require 'lib/evidence/facet_filter'
require 'app/resources/evidence_transform'
require 'app/helpers/pager'

module OpenBEL
  module Routes

    class Evidence < Base
      include OpenBEL::Evidence::FacetFilter
      include OpenBEL::Resource::Evidence
      include OpenBEL::Helpers

      def initialize(app)
        super

        # TODO Remove this from config.yml; put in app-config.rb as an "evidence-store" component.
        @api = OpenBEL::Settings["evidence-api"].create_instance

        # RdfRepository using Jena
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
            :tdb_directory => 'biological-concepts-rdf'
        )

        # Annotations using RdfRepository
        annotations = BEL::Resource::Annotations.new(@rr)

        @annotation_transform = AnnotationTransform.new(annotations)
        @annotation_grouping_transform = AnnotationGroupingTransform.new
      end

      helpers do

        def stream_evidence_objects(cursor)

          stream :keep_open do |response|
            cursor.each do |evidence|
              evidence.delete('facets')

              response << render_resource(
                  evidence,
                  :evidence,
                  :as_array => false,
                  :_id      => evidence['_id'].to_s
              )
            end
          end
        end

        def stream_evidence_array(cursor)
          stream :keep_open do |response|
            current = 0

            # determine true size of cursor given cursor limit/count
            if cursor.limit.zero?
              total = cursor.total
            else
              total = [cursor.limit, cursor.count].min
            end

            response << '['
            cursor.each do |evidence|
              evidence.delete('facets')

              response << render_resource(
                  evidence,
                  :evidence,
                  :as_array => false,
                  :_id      => evidence['_id'].to_s
              )
              current += 1
              response << ',' if current < total
            end
            response << ']'
          end
        end
      end

      options '/api/evidence' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/evidence/:id' do
        response.headers['Allow'] = 'OPTIONS,GET,PUT,DELETE'
        status 200
      end

      post '/api/evidence' do
        _id = nil
        read_evidence.each do |evidence|
          @annotation_transform.transform_evidence!(evidence, base_url)

          # XXX Not sure we need to group values together. Instead we split
          # multi-valued items into individual objects.
          # Wait and see what breaks.
          #@annotation_grouping_transform.transform_evidence!(evidence)

          facets = map_evidence_facets(evidence)
          hash = evidence.to_h
          hash[:bel_statement] = hash.fetch(:bel_statement, nil).to_s
          hash[:facets]        = facets
          _id = @api.create_evidence(hash)
        end

        status 201
        headers "Location" => "#{base_url}/api/evidence/#{_id}"
      end

			get '/api/evidence-stream', provides: 'application/json' do
        start                = (params[:start] || 0).to_i
        size                 = (params[:size]  || 0).to_i
        group_as_array       = as_bool(params[:group_as_array])

        # check filters
        filters = []
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = read_filter(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}

          if filter['category'] == 'fts' && filter['name'] == 'search'
            halt 400 unless filter['value'].to_s.length > 1
          end

          filters << filter
        end

        cursor  = @api.find_evidence(filters, start, size, false)[:cursor]
        if group_as_array
          stream_evidence_array(cursor)
        else
          stream_evidence_objects(cursor)
        end
			end

      get '/api/evidence' do
        start                = (params[:start]  || 0).to_i
        size                 = (params[:size]   || 0).to_i
        faceted              = as_bool(params[:faceted])
        max_values_per_facet = (params[:max_values_per_facet] || 0).to_i

        # check filters
        filters = []
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        filter_params.each do |filter|
          filter = read_filter(filter)
          halt 400 unless ['category', 'name', 'value'].all? { |f| filter.include? f}

          if filter['category'] == 'fts' && filter['name'] == 'search'
            halt 400 unless filter['value'].to_s.length > 1
          end

          filters << filter
        end

        collection_total  = @api.count_evidence()
        filtered_total    = @api.count_evidence(filters)
        page_results      = @api.find_evidence(filters, start, size, faceted)
        evidence          = page_results[:cursor].map { |item|
          item.delete('facets')
          item
        }.to_a
        facets            = page_results[:facets]

        halt 404 if evidence.empty?

        pager = Pager.new(start, size, filtered_total)

        options = {
          :start    => start,
          :size     => size,
          :filters  => filter_params,
          :metadata => {
            :collection_paging => {
              :total                  => collection_total,
              :total_filtered         => pager.total_size,
              :total_pages            => pager.total_pages,
              :current_page           => pager.current_page,
              :current_page_size      => evidence.size,
            }
          }
        }

        if facets
          # group by category/name
          hashed_values = Hash.new { |hash, key| hash[key] = [] }
          facets.each { |facet|
            filter         = read_filter(facet['_id'])
            category, name = filter.values_at('category', 'name')
            next if !category || !name

            key = [category.to_sym, name.to_sym]
            facet_obj = {
              :value    => filter['value'],
              :filter   => facet['_id'],
              :count    => facet['count']
            }
            hashed_values[key] << facet_obj
          }

          if max_values_per_facet == 0
            facet_hashes = hashed_values.map { |(category, name), value_objects|
              {
                :category => category,
                :name     => name,
                :values   => value_objects
              }
            }
          else
            facet_hashes = hashed_values.map { |(category, name), value_objects|
              {
                :category => category,
                :name     => name,
                :values   => value_objects.take(max_values_per_facet)
              }
            }
          end

          options[:facets] = facet_hashes
        end

        # pager links
        options[:previous_page] = pager.previous_page
        options[:next_page]     = pager.next_page

        render_collection(evidence, :evidence, options)
      end

      get '/api/evidence/:id' do
        object_id = params[:id]
        halt 404 unless BSON::ObjectId.legal?(object_id)

        evidence = @api.find_evidence_by_id(object_id)
        halt 404 unless evidence

        evidence.delete('facets')

        # XXX Hack to return single resource wrapped as json array
        # XXX Need to better support evidence resource arrays in base.rb
        render_resource(
          evidence,
          :evidence,
          :as_array => false,
          :_id      => object_id
        )
      end

      put '/api/evidence/:id' do
        object_id = params[:id]
        halt 404 unless BSON::ObjectId.legal?(object_id)

        validate_media_type! "application/json", :profile => schema_url('evidence')

        ev = @api.find_evidence_by_id(object_id)
        halt 404 unless ev

        evidence_obj = read_json
        schema_validation = validate_schema(evidence_obj, :evidence)
        unless schema_validation[0]
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => schema_validation[1].join("\n") })
          )
        end

        # transformation
        evidence          = evidence_obj['evidence']
        evidence_model    = ::BEL::Model::Evidence.create(evidence)
        @annotation_transform.transform_evidence!(evidence_model, base_url)
        facets = map_evidence_facets(evidence_model)
        evidence = evidence_model.to_h
        evidence[:facets] = facets

        @api.update_evidence_by_id(object_id, evidence)

        status 202
      end

      delete '/api/evidence/:id' do
        object_id = params[:id]
        halt 404 unless BSON::ObjectId.legal?(object_id)

        ev = @api.find_evidence_by_id(object_id)
        halt 404 unless ev

        @api.delete_evidence_by_id(object_id)
        status 202
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
