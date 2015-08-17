require 'rubygems'
require 'bundler'

Bundler.setup
$: << File.expand_path('../../', __FILE__)
$: << File.expand_path('../../../lib', __FILE__)

require 'rack/cors'

require 'sinatra/async'
require 'sinatra/base'
require 'base_libs/routes/base'

require 'bel'
require 'hermann'
require 'hermann/producer'

def em_run(opts)

  EM.run do

    trap('HUP') do
      EM.stop_event_loop
    end

    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '9030'
    web_app = opts[:app]

    dispatch = Rack::Builder.app do
      map '/api/evidence' do
        run web_app
      end
    end

    unless ['thin', 'hatetepe', 'goliath'].include? server
      raise "Need an EM webserver, but #{server} is not one."
    end

    # Start the web server. Note that you are free to run other tasks
    # within your EM instance.
    Rack::Server.start({
      app:     dispatch,
      server:  server,
      Host:    host,
      Port:    port,
      signals: false
    })
  end
end

module OpenBEL
  module Apps

    class Evidence < Sinatra::Base
      register Sinatra::Async

      def initialize
        super
        @evidence_events_stream = Hermann::Producer.new(
          'evidence-events',
          ["localhost:#{ENV['KAFKA_PORT']}"]
        )
        @evidence_events_stream.connect
      end

      configure do
        set :threaded, false
      end

      use Rack::Deflater
      use Rack::Cors do
        allow do
          origins '*'
          resource '*',
            :headers     => :any,
            :methods     => [ :get, :post, :put, :delete, :options ],
            :max_age     => 1,
            :credentials => false,
            :expose      => [
              'Allow',
              'Content-Type',
              'Content-Encoding',
              'Content-Length',
              'ETag',
              'Last-Modified',
              'Link',
              'Location'
            ]
        end
      end
      disable :protection
      
      helpers do

        def base_url
          env['HTTP_X_REAL_BASE_URL'] ||
            "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}"
        end

        def read_evidence
          fmt = ::BEL::Extension::Format.formatters(request.media_type)
          if fmt
            ::BEL::Format.evidence(request.body, request.media_type)
          else
            ahalt 415
          end
        end
      end

      apost '' do
        count = 0
        read_evidence.each do |evidence|
          @evidence_events_stream.push(MultiJson.dump(evidence.to_h))
          count += 1
        end

        body MultiJson.dump({
          :count  => count,
          :status => :complete
        })
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
