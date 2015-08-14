require 'rubygems'
require 'bundler'

Bundler.setup
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

require 'config/config'
require 'app/util'

require 'rack/cors'

require 'sinatra/async'
require 'sinatra/base'
require 'app/routes/base'

require 'bel'
require 'hermann'
require 'hermann/producer'

def run(opts)

  # Start the reactor
  $stderr.puts "starting reactor, stand back..."
  EM.run do

    # define some defaults for our app
    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '8181'
    web_app = opts[:app]

    dispatch = Rack::Builder.app do
      map '/api/streaming' do
        run web_app
      end
    end

    # NOTE that we have to use an EM-compatible web-server. There
    # might be more, but these are some that are currently available.
    unless ['thin', 'hatetepe', 'goliath'].include? server
      raise "Need an EM webserver, but #{server} isn't"
    end

    # Start the web server. Note that you are free to run other tasks
    # within your EM instance.
    Rack::Server.start({
      app:    dispatch,
      server: server,
      Host:   host,
      Port:   port,
      signals: false
    })
  end
end

module OpenBEL
  module Apps

    class EvidenceStreaming < Sinatra::Base
      register Sinatra::Async

      def initialize
        super
        @evidence_events_stream = Hermann::Producer.new(
          'evidence-events',
          ["localhost:#{ENV['KAFKA_PORT']}"]
        )
        @evidence_events_stream.connect
        puts "connected to evidence-events topic"
      end

      configure :development do
        # pass
      end

      configure do
        set :threaded, false
        config = OpenBEL::Config::load('config.yml')
        OpenBEL.const_set :Settings, config
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
          halt 415 unless fmt
          ::BEL::Format.evidence(request.body, request.media_type)
        end
      end

      apost '/async-evidence' do
        count = 0
        read_evidence.each do |evidence|
          @evidence_events_stream.push(MultiJson.dump(evidence.to_h))
          count += 1
        end

        body MultiJson.dump({
          :count  => count,
          :status => :complete
        })
        #_id = nil
        #status 201
        #headers "Location" => "#{base_url}/api/evidence/#{_id}"
      end

      post '/evidence' do
        stream = nil
        stream(:keep_open) do |out|
          stream = out
        end

        EM.defer do
          count = 0
          read_evidence.each do |evidence|
            @evidence_events_stream.push(MultiJson.dump(evidence.to_h))
            stream << evidence.to_h
          end
        end

        _id = nil
        status 201
        headers "Location" => "#{base_url}/api/evidence/#{_id}"
      end
    end
  end
end

run(
  :app  => OpenBEL::Apps::EvidenceStreaming.new,
  :port => 9000
)
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
