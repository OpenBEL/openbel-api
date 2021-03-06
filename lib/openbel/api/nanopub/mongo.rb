require 'bel'
require 'bel_parser/expression/model'
require 'bel/nanopub/util'
require 'mongo'
require_relative 'api'
require_relative 'mongo_facet'

module OpenBEL
  module Nanopub

    class Nanopub
      include API
      include Mongo

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

        @collection      = @db[:nanopub]
        @nanopub_facets = NanopubFacets.new(options)

        # ensure all indexes are created and maintained
        ensure_all_indexes
      end

      def create_nanopub(nanopub)
        # insert nanopub; acknowledge journal
        if nanopub.respond_to?(:each_pair)
          _id = @collection.insert(nanopub, :w => 1, :j => true)

          # remove nanopub_facets after insert to facets
          remove_nanopub_facets(_id)
          _id
        elsif nanopub.respond_to?(:each)
          @collection.insert(nanopub.to_a, :w => 1, :j => true)
        else
          raise "nanopub type #{nanopub.class} cannot be inserted into Mongo."
        end
      end

      def find_nanopub_by_id(value)
        @collection.find_one(to_id(value))
      end

      def find_nanopub(filters = [], offset = 0, length = 0, facet = false, facet_value_limit = -1)
        if includes_fts_search?(filters)
          text_search = get_fts_search(filters)
          nanopub_aggregate(text_search, filters, offset, length, facet, facet_value_limit)
        else
          nanopub_query(filters, offset, length, facet, facet_value_limit)
        end
      end

      def find_dataset_nanopub(dataset, filters = [], offset = 0, length = 0, facet = false, facet_value_limit = -1)
        query_hash = to_query(filters)
        query_hash[:$and] ||= []
        query_hash[:$and].unshift({
          :_dataset => dataset[:identifier]
        })

        query_opts = query_options(
          query_hash,
          :skip  => offset,
          :limit => length,
          :sort  => [
            [:bel_statement, :asc]
          ]
        )

        results = {
          :cursor => @collection.find(query_hash, query_opts)
        }
        if facet
          facets_cursor = @nanopub_facets.find_facets(query_hash, filters, facet_value_limit)
          results[:facets] = facets_cursor.to_a
        end

        results
      end

      def find_all_namespace_references
        references = @collection.aggregate(
          [
            {
              :$project => {"references.namespaces" => 1}
            },
            {
              :$unwind => "$references.namespaces"
            },
            {
              :$project => {
                keyword: "$references.namespaces.keyword",
                type:    "$references.namespaces.type",
                domain:  "$references.namespaces.domain"
              }
            },
            {
              :$group => {
                _id: "$keyword",
                type: {
                  :$addToSet => "$type"
                },
                domain: {
                  :$addToSet => "$domain"
                }
              }
            },
            {
              :$unwind => "$type"
            },
            {
              :$unwind => "$domain"
            },
            {
              :$project => {
                keyword: "$_id", type: "$type", domain: "$domain", _id: 0
              }
            }
          ],
          {
            allowDiskUse: true,
            cursor: {}
          }
        )

        union = []
        remap = {}
        references.each do |obj|
          keyword = obj['keyword']
          type = obj['type']
          domain = obj['domain']
          uri = url = nil
          if type == :url
              url = domain
          elsif type == :uri
              uri = domain
          end
          args = [keyword, uri, url]
          namespace = BELParser::Expression::Model::Namespace.new(*args)
          union, new_remap =
            BEL::Nanopub.union_namespace_references(union, [namespace], 'incr')
          remap.merge!(new_remap)
        end

        remap
      end

      def find_all_annotation_references
        references = @collection.aggregate(
          [
            {
              :$project => {"references.annotations" => 1}
            },
            {
              :$unwind => "$references.annotations"
            },
            {
              :$project => {
                keyword: "$references.annotations.keyword",
                type:    "$references.annotations.type",
                domain:  "$references.annotations.domain"
              }
            },
            {
              :$group => {
                _id: "$keyword",
                type: {
                  :$addToSet => "$type"
                },
                domain: {
                  :$addToSet => "$domain"
                }
              }
            },
            {
              :$unwind => "$type"
            },
            {
              :$unwind => "$domain"
            },
            {
              :$project => {
                keyword: "$_id", type: "$type", domain: "$domain", _id: 0
              }
            }
          ],
          {
            allowDiskUse: true,
            cursor: {}
          }
        )

        union = []
        remap = {}
        references.each do |obj|
          annotation =
            BELParser::Expression::Model::Annotation.new(
              *obj.values_at('keyword', 'type', 'domain')
            )
          union, new_remap =
            BEL::Nanopub.union_annotation_references(union, [annotation], 'incr')
          remap.merge!(new_remap)
        end

        remap
      end

      def count_nanopub(filters = [])
        query_hash = to_query(filters)
        @collection.count(:query => query_hash)
      end

      def update_nanopub_by_id(value, nanopub)
        # add ObjectId to update
        _id = BSON::ObjectId(value)
        nanopub_h = nanopub.to_h
        nanopub_h[:_id] = _id

        # save nanopub; acknowledge journal
        @collection.save(nanopub_h, :j => true)

        # remove nanopub_facets after update to facets
        remove_nanopub_facets(_id)
        nil
      end

      def delete_facets
        @nanopub_facets.delete_all_facets
      end

      def delete_dataset(identifier)
        @collection.remove(
          { :"_dataset" => identifier },
          :j => true
        )
        @nanopub_facets.delete_all_facets
      end

      def delete_nanopub(value)
        if value.respond_to?(:each)
          value.each do |v|
            delete_nanopub_by_id(v)
          end
        else
          delete_nanopub_by_id(value)
        end
      end

      def delete_nanopub_by_query(query)
        @collection.remove(
          query,
          :j => true
        )
      end

      def delete_nanopub_by_id(value)
        # convert to ObjectId
        begin
          _id = to_id(value)
        rescue BSON::InvalidObjectId
          # indicate that a delete was unsuccessful
          false
        end

        # remove nanopub_facets before nanopub removal
        remove_nanopub_facets(_id)

        # remove nanopub; returns true
        @collection.remove(
          {
              :_id => _id
          },
          :j => true
        )
      end

      def ensure_all_indexes
        @collection.ensure_index(
          { :bel_statement => Mongo::ASCENDING },
          :background => true
        )
        @collection.ensure_index(
          { :"$**" => Mongo::TEXT },
          :background => true
        )
        @collection.ensure_index(
          { :_dataset => Mongo::ASCENDING },
          :background => true
        )
        @collection.ensure_index(
          { :"experiment_context.name" => Mongo::ASCENDING },
          :background => true
        )
        @collection.ensure_index(
          { :"metadata.name" => Mongo::ASCENDING },
          :background => true
        )
      end

      private

      def nanopub_query(filters = [], offset = 0, length = 0, facet = false, facet_value_limit = -1)
        query_hash = to_query(filters)
        query_opts = query_options(
          query_hash,
          :skip  => offset,
          :limit => length,
          :sort  => [
            [:bel_statement, :asc]
          ]
        )

        results = {
          :cursor => @collection.find(query_hash, query_opts)
        }
        if facet
          facets_cursor = @nanopub_facets.find_facets(query_hash, filters, facet_value_limit)
          results[:facets] = facets_cursor.to_a
        end

        results
      end

      def nanopub_aggregate(text_search, filters = [], offset = 0, length = 0, facet = false, facet_value_limit = -1)
        match_filters = filters.select { |filter|
          filter['category'] != 'fts'
        }
        match = build_filter_query(match_filters)
        match[:$and].unshift({
          :$text => {
            :$search => text_search
          }
        })

        pipeline = [
          {
            :$match => match
          },
          {
            :$project => {
              :_id           => 1,
              :bel_statement => 1,
              :score => {
                :$meta => 'textScore'
              }
            }
          },
          {
            :$sort => {
              :score => {
                :$meta => 'textScore'
              },
              :bel_statement => 1
            }
          }
        ]

        if offset > 0
          pipeline << {
            :$skip => offset
          }
        end

        if length > 0
          pipeline << {
            :$limit => length
          }
        end

        fts_cursor = @collection.aggregate(pipeline, {
          :allowDiskUse => true,
          :cursor       => {
            :batchSize => 0
          }
        })
        _ids = fts_cursor.map { |doc| doc['_id'] }

        facets =
          if facet
            query_hash = to_query(filters)
            facets_cursor = @nanopub_facets.find_facets(query_hash, filters, facet_value_limit)
            facets_cursor.to_a
          else
            nil
          end

        {
          :cursor => @collection.find({:_id => {:$in => _ids}}),
          :facets => facets
        }
      end

      def includes_fts_search?(filters)
        filters.any? { |filter|
          filter['category'] == 'fts' && filter['name'] == 'search'
        }
      end

      def get_fts_search(filters)
        fts_filter = filters.find { |filter|
          filter['category'] == 'fts' && filter['name'] == 'search'
        }
        fts_filter.fetch('value', '')
      end

      def build_filter_query(filters = [])
        {
          :$and => filters.map { |filter|
            category = filter['category']
            name     = filter['name']
            value    = filter['value']

            case category
            when 'experiment_context'
              {
                :experiment_context => {
                  :$elemMatch => {
                    :name  => name.to_s,
                    :value => value.to_s
                  }
                }
              }
            when 'metadata'
              {
                :metadata => {
                  :$elemMatch => {
                    :name  => name.to_s,
                    :value => value.to_s
                  }
                }
              }
            else
              {
                "#{filter['category']}.#{filter['name']}" => filter['value'].to_s
              }
            end
          }
        }
      end

      def to_query(filters = [])
        if !filters || filters.empty?
          return {}
        end

        query_hash = {
          :$and => filters.map { |filter|
            category = filter['category']
            name     = filter['name']
            value    = filter['value']

						if category == 'fts' && name == 'search'
              {:$text => { :$search => value }}
            elsif category == 'experiment_context'
              {
                :experiment_context => {
                  :$elemMatch => {
                    :name  => name.to_s,
                    :value => value.to_s
                  }
                }
              }
            elsif category == 'metadata'
              {
                :metadata => {
                  :$elemMatch => {
                    :name  => name.to_s,
                    :value => value.to_s
                  }
                }
              }
            else
              {
                "#{filter['category']}.#{filter['name']}" => filter['value'].to_s
              }
            end
          }
        }

        query_hash
      end

      def query_options(query_hash, options = {})
        if query_hash[:$text]
          options[:fields] = [
            {
              :score => {
                :$meta => "textScore"
              }
            }
          ]
          options[:sort].unshift(
            [:score, {:$meta => "textScore"}]
          )
        end
        options
      end

      def to_id(value)
        BSON::ObjectId(value.to_s)
      end

      def remove_nanopub_facets(_id)
        doc = @collection.find_one(_id, {
          :fields => {:_id => 0, :facets => 1}
        })

        if doc && doc.has_key?('facets')
          @nanopub_facets.delete_facets(doc['facets'])
        end
      end
    end
  end
end
