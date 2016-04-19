require 'base64'
require 'sinatra/base'
require 'jwt'

module OpenBEL
  module JWTMiddleware

    def self.encode(payload, secret)
      ::JWT.encode(payload, secret, 'HS256')
    end

    def self.decode(token, secret, verify, options)
      ::JWT.decode(token, secret, verify, options)
    end

    def self.check_token(env)
      cookie_hdr = env['HTTP_COOKIE']
      auth_hdr = env['HTTP_AUTHORIZATION']
      req = Rack::Request.new(env)
      token_param = req.params['token']
      if cookie_hdr.nil? && auth_hdr.nil? && token_param.nil?
        raise 'missing authorization cookie, header, or parameter'
      end

      if not cookie_hdr.nil?
        cookies = cookie_hdr.split('; ')
        selected = cookies.select {|x| x.start_with?('jwt=') }
        if selected.size > 0
          tokens = selected[0].split('=')
          if tokens.size > 1
            token = tokens[1]
          end
        end
        if token.nil?
          raise 'malformed authorization cookie'
        end
      end

      if not auth_hdr.nil?
        tokens = auth_hdr.split('Bearer ')
        if tokens.size != 2
            raise 'malformed authorization header'
        end
        token = tokens[1]
      end

      if not token_param.nil?
        token = token_param
      end

      secret = OpenBEL::Settings[:auth][:secret]
      secret = Base64.decode64(secret)
      # whether we should verify the token
      verify = true
      # JWT options passed to decode
      options = {}

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
            JWTMiddleware.check_token(env)
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
