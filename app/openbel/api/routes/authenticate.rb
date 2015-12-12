require 'uri'
require 'rest-client'

def current_host(env)
  scheme = env['rack.url_scheme'] || 'http'
  host = env['HTTP_HOST']
  "#{scheme}://#{host}"
end

def current_path(env)
  scheme = env['rack.url_scheme'] || 'http'
  host = env['HTTP_HOST']
  path = env['PATH_INFO']
  "#{scheme}://#{host}#{path}"
end

module OpenBEL
  module Routes

    class Authenticate < Base

      get '/api/authenticate' do
        state = params[:state]
        code = params[:code]
        if code.nil?
          default_connection = OpenBEL::Settings[:auth][:default_connection]
          default_auth_url = current_path(env) + "/#{default_connection}"
          if not state.nil?
            default_auth_url += "?state=#{state}"
          end
          redirect to(default_auth_url)
        end

        domain = OpenBEL::Settings[:auth][:domain]
        id = OpenBEL::Settings[:auth][:id]
        secret = OpenBEL::Settings[:auth][:secret]

        callback_url = current_path(env)
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
        msg = {success: email}
        cookies[:jwt] = jwt
        if not state.nil?
          redirect to(state + "?jwt=#{jwt}")
        else
          [200, hdrs, [msg.to_json]]
        end
      end

      get '/api/authenticate/:connection' do
        state = params[:state]
        redirect_setting = OpenBEL::Settings[:auth][:redirect]
        connection = params[:connection]
        redirect_uri = current_host(env) + '/api/authenticate'
        auth_url = "#{redirect_setting}"
        auth_url += "&redirect_uri=#{redirect_uri}"
        auth_url += "&connection=#{connection}"
        if not state.nil?
          auth_url += "&state=#{state}"
        end
        redirect to(auth_url)
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
