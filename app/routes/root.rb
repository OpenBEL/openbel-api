require 'bel'

module OpenBEL
  module Routes

    class Root < Base
      include BEL::Language

      get '/api' do
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :_links => {
            :item => [
              {
                :href => "#{proxy_base_url}/expressions"
              },
              {
                :href => "#{proxy_base_url}/functions"
              },
              {
                :href => "#{proxy_base_url}/namespaces"
              }
            ]
          }
        })
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
