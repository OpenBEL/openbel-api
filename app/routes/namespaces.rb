require 'rack'
require 'sinatra/base'
require 'sinatra/reloader'
require 'cgi'
require 'oj'

APP_ROOT = OpenBEL::Util::path(File.dirname(__FILE__), '..')

require 'app/resources/html'
require 'app/resources/namespace'

module OpenBEL
  module Routes

    # App
    class Namespaces < Base

      RESULT_TYPES = {
        :resource => :all,
        :name => :prefLabel,
        :identifier => :identifier,
        :title => :title
      }

      def initialize(app)
        super
        @api = OpenBEL::Settings.namespace_api
      end

      # @macro [attach] sinatra.get
      #   @overload get "$1"
      # @method get_namespaces
      # Returns all namespaces.
      # WORKS
      get '/namespaces/?' do
        namespaces = @api.find_namespaces

        halt 404 if not namespaces or namespaces.empty?

        render_multiple(request, namespaces.sort { |x,y|
          x.prefLabel.to_s <=> y.prefLabel.to_s
        }, 'All Namespaces')
      end

      # WORKS
      get '/namespaces/:namespace/?' do |namespace|
        ns = @api.find_namespace(namespace)

        halt 404 unless ns

        status 200
        render_single(request, ns, 'Namespace')
      end

      get '/namespaces/:namespace/equivalents/?' do |namespace|
        halt 400 unless request.params['value']

        values = CGI::parse(env["QUERY_STRING"])['value']
        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        eq_mapping = @api.find_equivalents(namespace, values, options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump eq_mapping
      end

      post '/namespaces/:namespace/equivalents/?' do |namespace|
        halt 400 unless request.media_type == 'application/json'

        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        request.body.rewind
        json_body = JSON.parse request.body.read
        halt 400 unless json_body['values']

        eq_mapping = @api.find_equivalents(namespace, json_body['values'], options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump(eq_mapping)
      end

      get '/namespaces/:namespace/orthologs/?' do |namespace|
        halt 400 unless request.params['value']

        values = CGI::parse(env["QUERY_STRING"])['value']
        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        eq_mapping = @api.find_orthologs(namespace, values, options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump eq_mapping
      end

      post '/namespaces/:namespace/orthologs/?' do |namespace|
        halt 400 unless request.media_type == 'application/json'

        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        request.body.rewind
        json_body = JSON.parse request.body.read
        halt 400 unless json_body['values']

        eq_mapping = @api.find_orthologs(namespace, json_body['values'], options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump(eq_mapping)
      end

      # WORKS (Most of AFFX missing due to gdbm build)
      get '/namespaces/:namespace/:id/?' do |namespace, value|
        value = @api.find_namespace_value(namespace, value)

        halt 404 unless value

        status 200
        render_single(request, value, 'Namespace Value')
      end

      # BROKEN (Equivalent concept uri not saved; add to eq_array and ol_array
      get '/namespaces/:namespace/:id/equivalents/?' do |namespace, value|
        equivalents = @api.find_equivalent(namespace, value)
        halt 404 if not equivalents or equivalents.empty?

        render_multiple(request, equivalents, "Equivalents for #{namespace} / #{value}")
      end

      get '/namespaces/:namespace/:id/equivalents/:target/?' do |namespace, value, target|
        equivalent = @api.find_equivalent(namespace, value, {
          target: target
        })

        halt 404 unless equivalent

        render_single(request, equivalent, "Equivalent for #{namespace} / #{value} in #{target}")
      end

      get '/namespaces/:namespace/:id/orthologs/?' do |namespace, value|
        orthologs = @api.find_ortholog(namespace, value)
        if not orthologs or orthologs.empty?
          halt 404
        end

        render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value}")
      end

      get '/namespaces/:namespace/:id/orthologs/:target/?' do |namespace, value, target|
        orthologs = @api.find_ortholog(namespace, value, {
          target: target
        })
        if not orthologs or orthologs.empty?
          halt 404
        end

        render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value} in #{target}")
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
