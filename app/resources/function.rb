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
            p.short_form  item[:short_form]
            p.long_form   item[:long_form]
            p.description item[:description]
            p.return_type item[:return_type]
            p.signatures  item[:signatures]
          end
        end
      end

      class FunctionResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :function
          properties do |p|
            p.functions      item
          end

          link :self,        link_self(item.first[:short_form])
          link :next,        link_next
          link :collection,  link_collection
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
            :type => :'function_collection',
            :href => "#{base_url}/api/functions"
          }
        end

        def link_next
          fx_values = FUNCTIONS.values.uniq.sort_by { |fx|
            fx[:short_form]
          }
          next_fx = fx_values[fx_values.index(item) + 1]
          {
            :type => :function,
            :href => next_fx ?
                       "#{base_url}/api/functions/#{next_fx[:short_form]}" :
                       nil
          }
        end
      end

      class FunctionCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'function_collection'
          properties do |p|
            p.functions      item
          end

          link :self,       link_self
          link :start,      link_start(item.first[:short_form])
        end

        private

        def link_self
          {
            :type => :'function_collection',
            :href => "#{base_url}/api/functions"
          }
        end

        def link_start(first_function)
          {
            :type => :function,
            :href => "#{base_url}/api/functions/#{first_function}"
          }
        end
      end
    end
  end
end
