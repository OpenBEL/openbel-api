require 'uri'
require 'rest-client'

module OpenBEL
  module Routes

    class Authenticate < Base

      get '/api/authenticate' do
        code = params[:code]
        if code.nil?
          redirect to(OpenBEL::Settings[:auth][:redirect])
        end

        domain = OpenBEL::Settings[:auth][:domain]
        id = OpenBEL::Settings[:auth][:id]
        secret = OpenBEL::Settings[:auth][:secret]
        scheme = env['rack.url_scheme'] || 'http'
        host = env['HTTP_HOST']
        path = env['PATH_INFO']
        callback_url = "#{scheme}://#{host}#{path}"

        payload =  {
            client_id: id,
            client_secret: secret,
            redirect_uri: callback_url,
            code: code,
            grant_type: :authorization_code
        }

        token_url = "https://#{domain}/oauth/token"
        body = payload.to_json

        begin
          token_response = RestClient.post token_url, body,
                                           :content_type => :json,
                                           :accept => :json
        rescue => e
          hdrs = {'Content-Type' => 'application/json'}
          msg = {error: e.response }
          return [401, hdrs, [msg.to_json]]
        end

        token_response = JSON.parse(token_response)
        access_token = token_response['access_token']
        jwt = token_response['id_token']

        user_url = "https://#{domain}/userinfo?access_token=#{access_token}"
        begin
          user_response = RestClient.get user_url, :accept => :json
        rescue => e
          hdrs = {'Content-Type' => 'application/json'}
          msg = {error: e.response }
          return [401, hdrs, [msg.to_json]]
        end

        email = JSON.parse(user_response)['email']
        hdrs = {'Content-Type' => 'application/json'}
        msg = {success: email, token: jwt }
        return [200, hdrs, [msg.to_json]]
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
