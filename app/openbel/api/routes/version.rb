require 'openbel/api/version'

module OpenBEL
  module Routes
    # Version defines and implements the _/api/version_ route that exposes
    # the semantic version of the OpenBEL API.
    class Version < Base

      JSON             = Rack::Mime.mime_type('.json')
      HAL              = 'application/hal+json'
      TEXT             = Rack::Mime.mime_type('.txt')
      ACCEPTED_TYPES   = {
        'hal'  => HAL,
        'json' => JSON,
        'text' => TEXT
      }
      DEFAULT_TYPE     = TEXT

      helpers do
        def requested_media_type
          if params && params[:format]
            ACCEPTED_TYPES[params[:format]]
          else
            request.accept.flat_map { |accept_entry|
              ACCEPTED_TYPES.values.find { |type| type == accept_entry.entry }
            }.compact.first
          end
        end
      end

      options '/api/version' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/version' do
        accept_type = requested_media_type || DEFAULT_TYPE

        case accept_type
        when TEXT
          response.headers['Content-Type'] = 'text/plain'
          OpenBEL::Version.to_s
        when HAL, JSON
          response.headers['Content-Type'] = 'application/hal+json'
          MultiJson.dump({
            :version => {
              :string => OpenBEL::Version.to_s,
              :semantic_version => {
                :major => OpenBEL::Version::MAJOR,
                :minor => OpenBEL::Version::MINOR,
                :patch => OpenBEL::Version::PATCH
              }
            }
          })
        else
          halt 406
        end
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
