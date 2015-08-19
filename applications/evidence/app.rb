require 'rubygems'
require 'bundler'

Bundler.setup
$: << File.expand_path('../../', __FILE__)
$: << File.expand_path('../../../lib', __FILE__)

require 'multi_json'
require 'rack/cors'
require 'syslog/logger'
require 'thin'

require 'sinatra/async'
require 'sinatra/base'
require 'base_libs/routes/base'

require 'bel'
require 'hermann'
require 'hermann/producer'
require 'uuid'

def em_run(opts)

  EM.run do

    trap('HUP') do
      EM.stop_event_loop
    end

    server  = 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '9030'
    web_app = opts[:app]

    # Thin::Logging.logger = Syslog::Logger.new 'app-evidence'

    dispatch = Rack::Builder.app do
      map '/api/evidence' do
        run web_app
      end
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

      def initialize(options = {})
        super
        @evidence_events_stream = Hermann::Producer.new(
          options[:topic],
          options[:brokers]
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

        def schema_url(name)
          "http://next.belframework.org/schema/#{name}.schema.json"
        end

        def validate_media_type!(content_type, options = {})
          ctype = request.content_type
          valid = ctype.start_with? content_type
          if options[:profile]
            valid &= (%r{profile=#{options[:profile]}} =~ ctype)
          end

          ahalt 415 unless valid
        end

        def read_json
          request.body.rewind
          begin
            MultiJson.load request.body.read
          rescue MultiJson::ParseError => ex
            halt(
              400,
              {
                'Content-Type' => 'application/json'
              },
              render_json({
                :status => 400,
                :msg => 'Invalid JSON body.',
                :detail => ex.cause.to_s
              })
            )
          end
        end

        def read_evidence
          fmt = ::BEL::Extension::Format.formatters(request.media_type)
          if fmt
            ::BEL::Format.evidence(request.body, request.media_type)
          else
            ahalt 415
          end
        end

        def evidence_event(action, evidence = nil, options = {})
          case action
          when :create
            {
              event: {
                type:   'evidence',
                action: action,
                data:   {
                  uuid:     options[:uuid],
                  evidence: evidence,
                }
              }
            }
          when :update
            {
              event: {
                type:   'evidence',
                action: action,
                data:   {
                  uuid:     options[:uuid],
                  evidence: evidence,
                }
              }
            }
          when :delete
            {
              event: {
                type:   'evidence',
                action: action,
                data:   {
                  uuid: options[:uuid],
                }
              }
            }
          end
        end
      end

      apost '' do
        count = 0
        read_evidence.each do |evidence|
          evidence_obj = evidence.to_h

          # generate a new UUID for this evidence
          new_uuid = UUID.generate

          # put uuid in metadata
          (evidence_obj[:metadata] ||= {})[:__uuid__] = new_uuid

          # put uuid in create evidence event
          event = evidence_event(:create, evidence.to_h, :uuid => new_uuid)

          # push create evidence event to evidence-raw-events stream
          @evidence_events_stream.push(MultiJson.dump(event))

          count += 1
        end

        body MultiJson.dump({
          :count  => count,
          :status => :complete
        })
      end

      aget '' do
        body MultiJson.dump([])
      end

      aput '/:uuid' do
        uuid = params[:uuid]
        validate_media_type! "application/json", :profile => schema_url('evidence')

        evidence_obj = read_json
        # TODO Make all of schema validation available in libs.
        # schema_validation = validate_schema(evidence_obj, :evidence)
        # unless schema_validation[0]
        #   ahalt(
        #     400,
        #     { 'Content-Type' => 'application/json' },
        #     render_json({ :status => 400, :msg => schema_validation[1].join("\n") })
        #   )
        # end

        # put uuid in metadata
        (evidence_obj[:metadata] ||= {})[:__uuid__] = uuid

        event = evidence_event(:update, evidence_obj['evidence'], :uuid => uuid)
        @evidence_events_stream.push(MultiJson.dump(event))

        body MultiJson.dump({
          :status_code => 202,
          :count       => 1,
        })
      end

      adelete '/:uuid' do
        uuid = params[:uuid]
        
        event = evidence_event(:delete, nil, :uuid => uuid)
        @evidence_events_stream.push(MultiJson.dump(event))

        body MultiJson.dump({
          :status_code => 202,
          :count       => 1,
        })
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
