require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Evidence

      class EvidenceJsonSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :evidence
          properties do |p|
            p.bel_statement      item['bel_statement']
            p.citation           item['citation']
            p.biological_context item['biological_context']
            p.metadata           item['metadata']
          end
        end
      end

      class EvidenceHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'evidence-collection'
          properties do |p|
            p.bel_statement      item['bel_statement']
            p.citation           item['citation']
            p.biological_context item['biological_context']
            p.metadata           item['metadata']
          end

          link :self,         link_self(item['_id'])
          link :collection,   link_collection
        end

        private

        def link_self(id)
          {
            :type => :evidence,
            :href => "#{base_url}/api/evidence/#{id}"
          }
        end

        def link_collection
          {
            :type => :'evidence-collection',
            :href => "#{base_url}/api/evidence"
          }
        end
      end

      class EvidenceCollectionJsonSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'evidence-collection'
          properties do |p|
            collection :evidence, item, EvidenceJsonSerializer
            p.facets   context[:facets]
          end
        end
      end

      class EvidenceCollectionHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'evidence-collection'
          properties do |p|
            collection :evidence, item, EvidenceHALSerializer
            p.facets   context[:facets]
          end

          link :self,       link_self
          link :start,      link_start
          link :next,       link_next
        end

        private

        def link_self
          offset  = context[:offset]
          length  = context[:length]
          {
            :type => :'evidence-collection',
            :href => "#{base_url}/api/evidence?offset=#{offset}&length=#{length}&#{filter_query_params.join('&')}"
          }
        end

        def link_start
          length = context[:length]
          {
            :type => :'evidence-collection',
            :href => "#{base_url}/api/evidence?offset=0&length=#{length}&#{filter_query_params.join('&')}"
          }
        end

        def link_next
          offset  = context[:offset]
          length  = context[:length]
          {
            :type => :'evidence-collection',
            :href => context[:last] ?
                       nil :
                       "#{base_url}/api/evidence?offset=#{offset+length}&length=#{length}&#{filter_query_params.join('&')}"
          }
        end

        def filter_query_params
          context[:filters].map { |filter|
            "filter=#{filter}"
          }
        end
      end
    end
  end
end
