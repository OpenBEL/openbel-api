module OpenBEL
  module Routes

    class Language < Base

      options '/api/language' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/language' do
        response.headers['Content-Type'] = 'application/hal+json'
        MultiJson.dump({
          :_links => {
            :item => [
              {
                :href => "#{base_url}/api/language/functions"
              },
              {
                :href => "#{base_url}/api/language/relationships"
              },
              {
                :href => "#{base_url}/api/language/version"
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
