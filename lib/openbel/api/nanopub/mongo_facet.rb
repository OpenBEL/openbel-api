require 'mongo'
require 'multi_json'
require_relative 'facet_api'
require_relative 'facet_filter'
require_relative '../helpers/uuid_generator'

module OpenBEL
  module Nanopub

    class NanopubFacets
      include FacetAPI
      include Mongo
      include FacetFilter
      include ::OpenBEL::Helpers::UUIDGenerator

      def initialize(options = {})
        host = options[:host]
        port = options[:port]
        db   = options[:database]
        @db  = MongoClient.new(
          host,
          port,
          :op_timeout => nil,
          :pool_size  => 30
        ).db(db)

        # Authenticate user if provided.
        username = options[:username]
        password = options[:password]
        if username && password
          auth_db = options[:authentication_database] || db
          @db.authenticate(username, password, nil, auth_db)
        end

        @nanopub             = @db[:nanopub]
        @nanopub_facet_cache = @db[:nanopub_facet_cache]

        # ensure all indexes are created and maintained
        ensure_all_indexes
      end

      def find_facets(query, filters, facet_value_limit = -1)
        sorted_filters = sort_filters(filters)
        cache_collection = facet_cache_collection(sorted_filters)

        if no_collection?(cache_collection)
          cache_collection = "nanopub_facet_cache_#{generate_uuid}"
          create_aggr      = create_aggregation(cache_collection, query)
          @nanopub.aggregate(create_aggr[:pipeline], create_aggr[:options])
          @nanopub_facet_cache.insert({
            :filters          => sorted_filters,
            :cache_collection => cache_collection
          })
        end

        # set up field projection based on value limit
        field_projection = {
          :_id      => 0,
          :category => 1,
          :name     => 1,
          :values   => 1
        }
        if facet_value_limit > 0
          field_projection[:values] = {:$slice => facet_value_limit}
        end

        # cursor facets and apply "filter"
        @db[cache_collection].find({}, :fields => field_projection).map { |facet_doc|
          category, name     = facet_doc.values_at('category', 'name')
          facet_doc['values'].each do |value|
            value[:filter] = MultiJson.dump({
              :category => category,
              :name     => name,
              :value    => value['value']
            })
          end
          facet_doc
        }
      end

      def delete_facets(facets)
        # Add zero-filter to facets; clears the default search
        facets = facets.to_a
        facets.unshift([])

        # Drop facet cache collections
        @nanopub_facet_cache.find(
          {:filters => {:$in => facets}},
          :fields => {:_id => 0, :cache_collection => 1}
        ).each do |doc|
          cache_collection = doc['cache_collection']
          @db[cache_collection].drop()
        end

        # remove filter match entries in nanopub_facet_cache
        @nanopub_facet_cache.remove({:filters => {:$in => facets}})
      end

      def delete_all_facets
        @nanopub_facet_cache.find(
          {},
          :fields => {:_id => 0, :cache_collection => 1}
        ).each do |doc|
          cache_collection = doc['cache_collection']
          @db[cache_collection].drop()
        end

        # remove all entries in nanopub_facet_cache
        @nanopub_facet_cache.remove({})
      end

      def ensure_all_indexes
        @nanopub_facet_cache.ensure_index([
            [:"filters.category",   Mongo::ASCENDING],
            [:"filters.name",       Mongo::ASCENDING]
          ],
          :background => true
        )
      end

      private

      def no_collection?(collection)
        !collection || !@db.collection_names.include?(collection)
      end

      def sort_filters(filters)
        filters.sort { |f1, f2|
          f1_array = f1.values_at(:category, :name, :value)
          f2_array = f2.values_at(:cat, :name, :value)

          f1_array <=> f2_array
        }
      end

      def facet_cache_collection(filters)
        result = @nanopub_facet_cache.find_one(
          {:filters => filters},
          :fields => {:cache_collection => 1, :_id => 0}
        )

        result && result['cache_collection']
      end

      def create_aggregation(out_collection, match_query = {}, options = {})
        pipeline = CREATE_AGGREGATION[:pipeline] + [{ :$out => out_collection }]
        unless match_query.empty?
          pipeline.unshift({ :$match => match_query })
        end

        {
          :pipeline => pipeline,
          :options  => CREATE_AGGREGATION[:options].merge(options)
        }
      end

      # Define the aggregation pipeline
      CREATE_AGGREGATION = {
        :pipeline => [
          {
            :$project => {
              :_id => 0,
              :facets => 1
            }
          },
          {
            :$unwind => '$facets'
          },
          {
            :$group => {
              :_id => '$facets',
              :count => {
                :$sum => 1
              }
            }
          },
          {
            :$sort => {
              :count => -1
            }
          },
          {
            :$group => {
              :_id => {
                :category => '$_id.category',
                :name     => '$_id.name'
              },
              :values => {
                :$push => {
                  :value => '$_id.value',
                  :count => '$count'
                }
              }
            }
          },
          {
            :$project => {
              :category => '$_id.category',
              :name     => '$_id.name',
              :values   => { :$slice => ['$values', 1000] }
            }
          }
        ],
        :options => {
          :allowDiskUse => true
        }
      }
    end
  end
end
