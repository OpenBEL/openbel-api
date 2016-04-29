require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module Relationships

      class RelationshipSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :relationship
          properties do |p|
            p.short_form  item.short
            p.long_form   item.long
            p.description item.description
            p.return_type item.return_type.to_sym
          end
        end
      end

      class RelationshipResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :relationship
          properties do |p|
            p.relation      item
          end

          link :self,       link_self(item[:long_form])
          link :collection, link_collection
        end

        private

        def link_self(id)
          {
            :type => :relationship,
            :href => "#{base_url}/api/relationships/#{id}"
          }
        end

        def link_collection
          {
            :type => :relationship_collection,
            :href => "#{base_url}/api/relationships"
          }
        end
      end

      class RelationshipCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :relationship_collection
          properties do |p|
            p.relationship_collection item
          end

          link :self, link_self
        end

        private

        def link_self
          {
            :type => :relationship_collection,
            :href => "#{base_url}/api/relationships"
          }
        end
      end
    end
  end
end
