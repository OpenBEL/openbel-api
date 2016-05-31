require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Nanopub

      class NanopubSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :nanopub
          property :bel_statement,      item['bel_statement']
          property :citation,           item['citation']
          property :support,       item['support']
          property :experiment_context, item['experiment_context']
          property :metadata,           item['metadata']
          property :id,                 item['_id']
        end
      end

      class NanopubResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :nanopub
          properties do |p|
            p.nanopub item
          end

          link :self,         link_self
          link :collection,   link_collection
        end

        private

        def link_self
          id = item[:id] || context[:_id]
          item.delete(:id)
          {
            :type => :nanopub,
            :href => "#{base_url}/api/nanopubs/#{id}"
          }
        end

        def link_collection
          {
            :type => :nanopub_collection,
            :href => "#{base_url}/api/nanopubs"
          }
        end
      end

      class NanopubCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type     :nanopub_collection
          property :nanopub_collection,   item
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
            :type => :nanopub_collection,
            :href => "#{base_url}/api/nanopubs?start=#{start}&size=#{size}&#{filter_query_params.join('&')}"
          }
        end

        def link_start
          size = context[:size]
          {
            :type => :nanopub_collection,
            :href => "#{base_url}/api/nanopubs?start=0&size=#{size}&#{filter_query_params.join('&')}"
          }
        end

        def link_previous
          previous_page = context[:previous_page]
          return {} unless previous_page

          {
            :type => :nanopub_collection,
            :href => "#{base_url}/api/nanopubs?start=#{previous_page.start_offset}&size=#{previous_page.page_size}&#{filter_query_params.join('&')}"
          }
        end

        def link_next
          next_page = context[:next_page]
          return {} unless next_page

          {
            :type => :nanopub_collection,
            :href => "#{base_url}/api/nanopubs?start=#{next_page.start_offset}&size=#{next_page.page_size}&#{filter_query_params.join('&')}"
          }
        end

        def filter_query_params
          context[:filters].map { |filter|
            "filter=#{MultiJson.dump(filter)}"
          }
        end
      end
    end
  end
end
