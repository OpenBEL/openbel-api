require 'bel'

module OpenBEL
  module Routes

    class Functions < Base
      include BEL::Language

      get '/api/functions' do
        collection = {
          :_links => {
            :item => FUNCTIONS.keys.sort.map { |fx|
              {
                :href => "#{url}/#{fx}"
              }
            }
          }
        }

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :functions => collection
        })
      end

      # BEL Completion
      get '/api/functions/:fx' do
        fx_match = FUNCTIONS[params[:fx].to_sym]
        halt 404 unless fx_match

        fx_match[:_links] = {
          :self => {
            :href => url
          },
          :collection => {
            :href => "#{base_url}/api/functions"
          }
        }
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :function => fx_match
        })
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
