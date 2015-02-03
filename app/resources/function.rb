require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Functions

      class FunctionJsonSerializer < BaseSerializer
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

      class FunctionHALSerializer < BaseSerializer
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

          link :self,        link_self(item[:short_form])
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
            :type => :'function-collection',
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

      class FunctionCollectionJsonSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'function-collection'
          properties do |p|
            collection :functions, item, FunctionJsonSerializer
          end
        end
      end

      class FunctionCollectionHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'function-collection'
          properties do |p|
            collection :functions, item, FunctionJsonSerializer
          end

          link :self,       link_self
          link :start,      link_start(item[0][:short_form])
        end

        private

        def link_self
          {
            :type => :'function-collection',
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