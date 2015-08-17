require 'bel'
require_relative 'base'

module OpenBEL
  module Resource
    module MatchResults

      class MatchResultSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :match_result
          properties do |p|
            p.match_text     item.snippet
            p.rdf_uri        item.uri
            p.rdf_scheme_uri item.scheme_uri
            p.identifier     item.identifier
            p.name           item.pref_label

            # Do not have alt_labels property from FTS index.
            # p.synonyms       item.alt_labels
          end
        end
      end

      class MatchResultResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'match_result'
          properties do |p|
            collection :match_results, item, MatchResultSerializer
          end

          # link :self,        link_self(item.first[:short_form])
        end

        # private
        #
        # def link_self(id)
        #   {
        #     :type => :function,
        #     :href => "#{base_url}/api/functions/#{id}"
        #   }
        # end
      end

      class MatchResultCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL

        schema do
          type :'match_result_collection'
          properties do |p|
            collection :match_results, item, MatchResultSerializer
          end

          # link :self,       link_self
          # link :start,      link_start(item[0][:short_form])
        end

        # private
        #
        # def link_self
        #   {
        #     :type => :'function_collection',
        #     :href => "#{base_url}/api/functions"
        #   }
        # end
        #
        # def link_start(first_function)
        #   {
        #     :type => :function,
        #     :href => "#{base_url}/api/functions/#{first_function}"
        #   }
        # end
      end
    end
  end
end
