require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Evidence

      class EvidenceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'evidence'
          properties do |p|
            p.bel_statement      item['bel_statement']
            p.citation           item['citation']
            p.summary_text       item['summary_text']
            p.experiment_context prepare_experiment_context(
              item['experiment_context']
            )
            p.metadata           item['metadata']
          end

          link :self,         link_self(item['_id'])
          link :collection,   link_collection
        end

        private

        def prepare_experiment_context(experiment_context)
          experiment_context.each do |annotation|
            if annotation['uri']
              annotation.delete('name')
              annotation.delete('value')
            end
          end
          experiment_context
        end

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

      class EvidenceResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'evidence'
          properties do |p|
            collection :evidence, item, EvidenceSerializer
          end

          link :self,         link_self(item.first['_id'])
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

      class EvidenceCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'evidence-collection'
          properties do |p|
            p.evidence item
            p.facets   context[:facets]
          end

          link :self,       link_self
          link :start,      link_start
          link :next,       link_next
        end

        private

        def link_self
          start  = context[:start]
          size   = context[:size]
          {
            :type => :'evidence-collection',
            :href => "#{base_url}/api/evidence?start=#{start}&size=#{size}&#{filter_query_params.join('&')}"
          }
        end

        def link_start
          size = context[:size]
          {
            :type => :'evidence-collection',
            :href => "#{base_url}/api/evidence?start=0&size=#{size}&#{filter_query_params.join('&')}"
          }
        end

        def link_next
          start  = context[:start]
          size   = context[:size]
          {
            :type => :'evidence-collection',
            :href => "#{base_url}/api/evidence?start=#{start + size}&size=#{size}&#{filter_query_params.join('&')}"
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
