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

      unless cookie_hdr.nil?
        cookies = cookie_hdr.split('; ')
        selected = cookies.select { |x| x.start_with?('jwt=') }
        unless selected.empty?
          tokens = selected[0].split('=')
          token = tokens[1] if tokens.size > 1
        end
      end

      unless auth_hdr.nil?
        tokens = auth_hdr.split('Bearer ')
        raise 'malformed authorization header' if tokens.size != 2
        token = tokens[1]
      end

      token = token_param unless token_param.nil?

      secret = OpenBEL::Settings[:auth][:secret]
      pubkey = OpenSSL::PKey::RSA.new(secret)

      # secret = Base64.decode64(secret)

      # whether we should verify the token
      verify = true
      # JWT options passed to decode
      options = { :algorithm => 'RS256' }

      begin
        decoded_token = decode(token, pubkey, verify, options)
      rescue ::JWT::VerificationError => ve
        puts ve.inspect
        raise 'invalid authorization token'
      rescue ::JWT::DecodeError => je
        puts je.inspect
        raise 'malformed authorization token'
      end
      env['jwt.header'] = decoded_token.last unless decoded_token.nil?
      env['jwt.payload'] = decoded_token.first unless decoded_token.nil?

      exp = env['jwt.payload']['exp']
      now = Time.now.to_i
      raise 'token expired' if now > exp

      env['email'] = env['jwt.payload']['email']
    end

    class Authentication
      def initialize(app, opts = {})
        @app = app
        @paths = opts.fetch(:paths, [])
      end

      def call(env)
        check = false
        if @paths.empty?
          # w/out paths, always check for token
          check = true
        else
          path = env['PATH_INFO']
          # w/ paths, only check for token iff matched
          check = true if @paths.any? { |x| path.start_with?(x) }
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
        hdrs = { 'Content-Type' => 'application/json' }
        msg = { error: message }
        [401, hdrs, [msg.to_json]]
      end
    end
  end
end
