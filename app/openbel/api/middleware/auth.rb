require 'base64'
require 'sinatra/base'
require 'jwt'

def encode(payload, secret)
  ::JWT.encode(payload, secret, 'HS256')
end

def decode(token, secret, verify, options)
  ::JWT.decode(token, secret, verify, options)
end

def check_token(env)
  secret = OpenBEL::Settings[:auth][:secret]
  secret = Base64.decode64(secret)
  # whether we should verify the token
  verify = true
  # JWT options passed to decode
  options = {}

  auth_hdr = env['HTTP_AUTHORIZATION']
  if auth_hdr.nil?
    raise 'missing authorization header'
  elsif not auth_hdr.start_with?('Bearer ')
    raise 'malformed authorization header'
  end

  token = auth_hdr.split(' ')[-1]
  begin
    decoded_token = decode(token, secret, verify, options)
  rescue ::JWT::VerificationError => ve
    raise 'invalid authorization token'
  rescue ::JWT::DecodeError => je
    puts je.inspect
    raise 'malformed authorization token'
  end
  env['jwt.header'] = decoded_token.last unless decoded_token.nil?
  env['jwt.payload'] = decoded_token.first unless decoded_token.nil?

  exp = env['jwt.payload']['exp']
  now = Time.now.to_i
  if now > exp
    raise 'token expired'
  end

  env['email'] = env['jwt.payload']['email']
end

module OpenBEL
  module Middleware
    module JWT

      class Authentication
        def initialize(app, opts = {})
          @app          = app
          @paths       = opts.fetch(:paths, [])
        end

        def call(env)
          check = false
          if @paths.size == 0
            # w/out paths, always check for token
            check = true
          else
            path = env['PATH_INFO']
            # w/ paths, only check for token iff matched
            if @paths.any? {|x| path.start_with?(x)}
              check = true
            end
          end

          if check
            begin
              check_token(env)
            rescue Exception => e
              return _401(e.message)
            end
            @app.call(env)
          end
        end

        private

        def _401(message)
          hdrs = {'Content-Type' => 'application/json'}
          msg = {error: message }
          [401, hdrs, [msg.to_json]]
        end
      end
    end
  end
end
