module OpenBEL
  module Routes

    class Root < Base

      get '/api' do
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :_links => {
            :item => [
              {
                :href => "#{proxy_base_url}/api/expressions"
              },
              {
                :href => "#{proxy_base_url}/api/functions"
              },
              {
                :href => "#{proxy_base_url}/api/namespaces"
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