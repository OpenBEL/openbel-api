require          'bel/util'
require_relative 'base'
require_relative 'translators'

module OpenBEL
  module Helpers

    def render_nanopub_collection(
      name, page_results, start, size, filters,
      filtered_total, collection_total, nanopub_api
    )
      # see if the user requested a BEL translator (Accept header or ?format)
      translator        = Translators.requested_translator(request, params)
      translator_plugin = Translators.requested_translator_plugin(request, params)

      halt 404 unless page_results[:cursor].has_next?

      # Serialize to HAL if they [Accept]ed it, specified it as ?format, or
      # no translator was found to match request.
      if wants_default? || !translator
        facets   = page_results[:facets]
        pager    = Pager.new(start, size, filtered_total)
        nanopub = page_results[:cursor].map { |item|
                     item.delete('facets')
                     item
                   }.to_a

        options = {
          :facets   => facets,
          :start    => start,
          :size     => size,
          :filters  => filters,
          :metadata => {
            :collection_paging => {
              :total                  => collection_total,
              :total_filtered         => pager.total_size,
              :total_pages            => pager.total_pages,
              :current_page           => pager.current_page,
              :current_page_size      => nanopub.size,
            }
          }
        }

        # pager links
        options[:previous_page] = pager.previous_page
        options[:next_page]     = pager.next_page

        render_collection(nanopub, :nanopub, options)
      else
        extension = translator_plugin.file_extensions.first

        response.headers['Content-Type'] = translator_plugin.media_types.first
        status 200
        attachment "#{name}.#{extension}"
        stream :keep_open do |response|
          cursor             = page_results[:cursor]
          dataset_nanopub = cursor.lazy.map { |nanopub|
            nanopub.delete('facets')
            nanopub.delete('_id')
            nanopub = BEL::Nanopub::Nanopub.create(BEL.keys_to_symbols(nanopub))
            nanopub
          }

          translator.write(
            dataset_nanopub, response,
            :annotation_reference_map => nanopub_api.find_all_annotation_references,
            :namespace_reference_map  => nanopub_api.find_all_namespace_references
          )
        end
      end
    end
  end
end
