require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Evidence

      class Evidence

        def initialize(statement_or_hash, options = {})
          if statement_or_hash.kind_of?(String)
            @bel_statement = statement_or_hash
          elsif statement_or_hash.kind_of?(Hash)
            statement_or_hash.each { |k,v|
              send("#{k}=",v)
            }
          else
            fail ArgumentError.new("statement_or_hash must be one of String or Hash")
          end
        end

        def bel_statement
          @bel_statement
        end

        def bel_statement= statement
          @bel_statement = statement.to_s
        end

        def citation
          @citation
        end

        def citation= citation
          @citation = citation
        end

        def biological_context
          @biological_context
        end

        def biological_context= biological_context
          @biological_context = biological_context
        end

        def summary_text
          @summary_text
        end

        def summary_text= summary_text
          @summary_text = summary_text.to_s
        end
      end

      class EvidenceJsonSerializer < BaseSerializer
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
