require 'bel'
require 'bel_parser'

module OpenBEL
  module Routes
    # Language defines and implements the _/api/language_ routes to expose
    # BEL functions, relationships, and version configured for the API.
    class Language < Base

      JSON             = Rack::Mime.mime_type('.json')
      TEXT             = Rack::Mime.mime_type('.txt')
      ACCEPTED_TYPES   = {'json' => JSON, 'text' => TEXT}
      DEFAULT_TYPE     = TEXT

      def initialize(app)
        super
        bel_version = OpenBEL::Settings[:bel][:version]
        @spec       = BELParser::Language.specification(bel_version)
      end

      configure :development do |config|
        Language.reset!
        use Rack::Reloader
      end

      options '/api/language' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/language/functions' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/language/functions/:fx' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/language/relationships' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/language/relationships/:rel' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/language/version' do
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

      get '/api/language/functions' do
        render_collection(
          @spec.functions.sort_by(&:long),
          :function)
      end

      get '/api/language/functions/:fx' do
        function = @spec.function(params[:fx].to_sym)
        halt 404 unless function
        render_resource(function, :function)
      end

      get '/api/language/relationships' do
        render_collection(
          @spec.relationships.sort_by(&:long),
          :relationship)
      end

      get '/api/language/relationships/:rel' do
        relationship = @spec.relationship(params[:rel].to_sym)
        halt 404 unless relationship
        render_resource(relationship, :relationship)
      end

      get '/api/language/version' do
        accept_type = request.accept.find { |accept_entry|
          ACCEPTED_TYPES.values.include?(accept_entry.to_s)
        }
        accept_type ||= DEFAULT_TYPE

        format = params[:format]
        if format
          accept_type = ACCEPTED_TYPES[format]
          halt 406 unless accept_type
        end

        render_json(
          {
            :bel_version => {
              :string => OpenBEL::Settings[:bel][:version].to_s
            }
          }
        )
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
