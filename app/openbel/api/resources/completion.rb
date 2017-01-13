require_relative 'base'

module OpenBEL
  module Resource
    module Expressions

      class CompletionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :completion
          property :type,           item[:type]
          property :id,             item[:id]
          property :label,          item[:label]
          property :value,          item[:value]
          property :caret_position, item[:caret_position]
          property :validation,     item[:validation]
        end
      end

      class CompletionResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :completion
          properties do |p|
            p.completion item
          end

          link :describedby, link_described_by(item[:type], item[:id])
        end

        private

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
          when :relationship
            {
              :type => 'relationship',
              :href => "#{base_url}/api/relationships/#{id}"
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
            p.completion_collection item
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
