require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Evidence

      class EvidenceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :evidence
          properties do |p|
            p.bel_statement      item['bel_statement']
            p.citation           item['citation']
            p.summary_text       item['summary_text']
            p.experiment_context item['experiment_context']
            p.metadata           item['metadata']
          end
        end
      end

      class EvidenceResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :evidence
          properties do |p|
            p.evidence item
          end

          link :self,         link_self
          link :collection,   link_collection
        end

        private

        def link_self
          id = item['_id'] || context[:_id]
          item.delete('_id')
          {
            :type => :evidence,
            :href => "#{base_url}/api/evidence/#{id}"
          }
        end

        def link_collection
          {
            :type => :evidence_collection,
            :href => "#{base_url}/api/evidence"
          }
        end
      end

      class EvidenceCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type     :evidence_collection
          property :evidence_collection,   item
          property :facets,                context[:facets]
          property :metadata,              context[:metadata]
          link     :self,                  link_self
          link     :start,                 link_start
          link     :previous,              link_previous
          link     :next,                  link_next
        end

        private

        def link_self
          start  = context[:start]
          size   = context[:size]
          {
            :type => :evidence_collection,
            :href => "#{base_url}/api/evidence?start=#{start}&size=#{size}&#{filter_query_params.join('&')}"
          }
        end

        def link_start
          size = context[:size]
          {
            :type => :evidence_collection,
            :href => "#{base_url}/api/evidence?start=0&size=#{size}&#{filter_query_params.join('&')}"
          }
        end

        def link_previous
          previous_page = context[:previous_page]
          return {} unless previous_page

          {
            :type => :evidence_collection,
            :href => "#{base_url}/api/evidence?start=#{previous_page.start_offset}&size=#{previous_page.page_size}&#{filter_query_params.join('&')}"
          }
        end

        def link_next
          next_page = context[:next_page]
          return {} unless next_page

          {
            :type => :evidence_collection,
            :href => "#{base_url}/api/evidence?start=#{next_page.start_offset}&size=#{next_page.page_size}&#{filter_query_params.join('&')}"
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
