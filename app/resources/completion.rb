require_relative 'base'

module OpenBEL
  module Resource
    module Expressions

      class CompletionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :completion
          properties do |p|
            p.type      item[:type]
            p.label     item[:label]
            p.value     item[:value]
            p.highlight item[:highlight]
            p.actions   item[:actions]
          end
        end
      end

      class CompletionResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :completion
          properties do |p|
            collection :completions, item, CompletionSerializer
          end

          link :self,        link_self(item.first[:id])
          link :describedby, link_described_by(item.first[:type], item.first[:id])
        end

        private

        def link_self(id)
          {
            :type => 'completion',
            :href => "#{base_url}/api/expressions/#{id}/completions"
          }
        end

        def link_described_by(type, id)
          case type
          when :function
            {
              :type => 'function',
              :href => "#{base_url}/api/functions/#{id}"
            }
          when :namespace_prefix
            {
              :type => 'namespace_prefix',
              :href => "#{base_url}/api/namespaces/#{id}"
            }
          when :namespace_value
            {
              :type => 'namespace_value',
              :href => "#{base_url}/api/namespaces/hgnc/#{id}"
            }
          else
            raise NotImplementedError.new("Unexpected resource type, #{type}")
          end
        end
      end

      class CompletionCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :completion_collection
          properties do |p|
            collection :completions, item, CompletionSerializer
          end

          link :self,       link_self
        end

        private

        def link_self
          bel            = context[:bel]
          caret_position = context[:caret_position]
          {
            :type => :completion_collection,
            :href => "#{base_url}/api/expressions/#{bel}/completions?caret_position=#{caret_position}"
          }
        end
      end
    end
  end
end
