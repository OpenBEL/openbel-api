module OpenBEL
  module Routes

    class Root < Base

      options '/api' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api' do
        response.headers['Content-Type'] = 'application/hal+json'
        MultiJson.dump({
          :_links => {
            :item => [
              {
                :href => "#{base_url}/api/annotations"
              },
              {
                :href => "#{base_url}/api/evidence"
              },
              {
                :href => "#{base_url}/api/expressions"
              },
              {
                :href => "#{base_url}/api/functions"
              },
              {
                :href => "#{base_url}/api/relationships"
              },
              {
                :href => "#{base_url}/api/namespaces"
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
