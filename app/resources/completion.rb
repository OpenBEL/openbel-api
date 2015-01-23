require_relative 'base'

module OpenBEL
  module Resource
    module Expressions

      class CompletionJsonSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type "completion"
          properties do |p|
            p.type      item[:type]
            p.label     item[:label]
            p.value     item[:value]
            p.highlight item[:highlight]
            p.actions   item[:actions]
          end
        end
      end

      class CompletionHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type "completion"
          properties do |p|
            p.type      item[:type]
            p.label     item[:label]
            p.value     item[:value]
            p.highlight item[:highlight]
            p.actions   item[:actions]
          end

          link :self,        link_self(item[:id])
          link :describedby, link_described_by(item[:type], item[:id])
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
    end
  end
end
