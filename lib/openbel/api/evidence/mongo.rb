require 'bel'
require 'mongo'
require_relative 'api'
require_relative 'mongo_facet'

module OpenBEL
  module Evidence

    class Evidence
      include API
      include Mongo

      def initialize(options = {})
        host             = options.delete(:host)
        port             = options.delete(:port)
        db               = options.delete(:database)
        @db              = MongoClient.new(host, port).db(db)
        @collection      = @db[:evidence]
        @collection.ensure_index(
          {:"bel_statement" => Mongo::ASCENDING },
          :background => true
        )
        @collection.ensure_index(
          {:"$**" => Mongo::TEXT },
          :background => true
        )
        @evidence_facets = EvidenceFacets.new(
          :host     => host,
          :port     => port,
          :database => db
        )
      end

      def create_evidence(evidence)
        # insert evidence; acknowledge journal
        if evidence.respond_to?(:each_pair)
          _id = @collection.insert(evidence, :w => 1, :j => true)

          # remove evidence_facets after insert to facets
          remove_evidence_facets(_id)
          _id
        elsif evidence.respond_to?(:each)
          @collection.insert(evidence.to_a, :w => 1, :j => true)
        else
          raise "Evidence type #{evidence.class} cannot be inserted into Mongo."
        end
      end

      def find_evidence_by_id(value)
        @collection.find_one(to_id(value))
      end

      def find_evidence(filters = [], offset = 0, length = 0, facet = false)
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
          facets_doc = @evidence_facets.find_facets(query_hash, filters)
          results[:facets] = facets_doc["facets"]
        end

        results
      end

      def find_dataset_evidence(dataset, filters = [], offset = 0, length = 0, facet = false)
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
          facets_doc = @evidence_facets.find_facets(query_hash, filters)
          results[:facets] = facets_doc["facets"]
        end

        results
      end

      def count_evidence(filters = [])
        query_hash = to_query(filters)
        @collection.count(:query => query_hash)
      end

      def update_evidence_by_id(value, evidence)
        # add ObjectId to update
        _id = BSON::ObjectId(value)
        evidence_h = evidence.to_h
        evidence_h[:_id] = _id

        # save evidence; acknowledge journal
        @collection.save(evidence_h, :j => true)

        # remove evidence_facets after update to facets
        remove_evidence_facets(_id)
        nil
      end

      def delete_dataset(identifier)
        @collection.ensure_index(
          {:"_dataset" => Mongo::ASCENDING },
          :background => true
        )

        @collection.remove(
          { :"_dataset" => identifier },
          :j => true
        )
      end

      def delete_evidence(value)
        if value.respond_to?(:each)
          value.each do |v|
            delete_evidence_by_id(v)
          end
        else
          delete_evidence_by_id(value)
        end
      end

      def delete_evidence_by_query(query)
        @collection.remove(
          query,
          :j => true
        )
      end

      def delete_evidence_by_id(value)
        # convert to ObjectId
        begin
          _id = to_id(value)
        rescue BSON::InvalidObjectId
          # indicate that a delete was unsuccessful
          false
        end

        # remove evidence_facets before evidence removal
        remove_evidence_facets(_id)

        # remove evidence; returns true
        @collection.remove(
          {
              :_id => _id
          },
          :j => true
        )
      end

      private

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

      def remove_evidence_facets(_id)
        evidence = @collection.find_one(_id, {
          :fields => [ 'facets' ]
        })

        if evidence && evidence.has_key?('facets')
          @evidence_facets.remove_facets_by_filters(evidence['facets'])
          @evidence_facets.remove_facets_by_filters 
        end
      end
    end
  end
end
