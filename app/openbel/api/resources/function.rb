require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Functions

      class FunctionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :function
          properties do |p|
            p.short_form  item.short
            p.long_form   item.long
            p.description item.description
            p.return_type item.return_type.to_sym
          end
        end
      end

      class FunctionResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :function
          properties do |p|
            p.function      item
          end

          link :self,       link_self(item[:long_form])
          link :collection, link_collection
        end

        private

        def link_self(id)
          {
            :type => :function,
            :href => "#{base_url}/api/functions/#{id}"
          }
        end

        def link_collection
          {
            :type => :function_collection,
            :href => "#{base_url}/api/functions"
          }
        end
      end

      class FunctionCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :function_collection
          properties do |p|
            p.function_collection item
          end

          link :self, link_self
        end

        private

        def link_self
          {
            :type => :function_collection,
            :href => "#{base_url}/api/functions"
          }
        end
      end
    end
  end
end
