require 'bel'

module OpenBEL
  module Routes

    class Functions < Base
      include BEL::Language

      # BEL Completion
      get '/bel/functions/:fx/?' do
        fx_match = FUNCTIONS[params[:fx].to_sym]
        halt 404 unless fx_match

        fx_match[:_links] = {
          :self => proxy_url
        }
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump fx_match
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
