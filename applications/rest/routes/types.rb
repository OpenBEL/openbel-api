require 'bel'
require 'uri'

module OpenBEL
  module Routes

    class Types < Base

      def initialize(app)
        super
      end

      options '/api/types' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/types/:type' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/types/:type/schema' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/types/?' do
      end

      get '/api/types/:type/?' do |type|
      end

      get '/api/expressions/:type/schema/?' do |type|
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
