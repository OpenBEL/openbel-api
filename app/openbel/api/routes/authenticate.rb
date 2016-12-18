module OpenBEL
  module Routes

    class Authenticate < Base

      configure :development do |config|
        Authenticate.reset!
        use Rack::Reloader
      end

      get '/api/authentication-enabled' do
        enabled = OpenBEL::Settings[:auth][:enabled]
        hdrs = {'Content-Type' => 'application/json'}
        msg = {enabled: enabled}
        return [200, hdrs, [msg.to_json]]
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
