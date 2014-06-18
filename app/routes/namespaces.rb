require 'rack'
require 'sinatra/base'
require 'sinatra/reloader'
require 'cgi'
require 'oj'

APP_ROOT = OpenBEL::Util::path(File.dirname(__FILE__), '..')

require 'openbel'
require 'storage_rdf/api'
require 'storage_rdf/extensions/redland'
require 'app/resources/html'
require 'app/resources/namespace'

module OpenBEL
  module Routes

    # App
    class Namespaces < Base

      def initialize(app)
        super
        @api = OpenBEL::Namespace::API.new OpenBEL::Settings.storage_rdf
      end

      # @macro [attach] sinatra.get
      #   @overload get "$1"
      # @method get_namespaces
      # Returns all namespaces.
      get '/namespaces/?' do
        namespaces = @api.find_namespaces
        if not namespaces or namespaces.empty?
          halt 404
        end

        render_multiple(request, namespaces.sort { |x,y|
          x.prefLabel.to_s <=> y.prefLabel.to_s
        }, 'All Namespaces')
      end

      get '/namespaces/:namespace/?' do |namespace|
        ns = @api.find_namespace(namespace)
        if not ns
          halt 404
        end

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
          halt 400 unless [:resource, :name, :identifier, :title].include? result
          options[:result] = result
        end

        eq_mapping = @api.find_equivalents(namespace, values, options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump eq_mapping
      end

      post '/namespaces/:namespace/equivalents/?' do |namespace|
        unless request.media_type == 'application/json'
          halt 400
        end

        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless [:resource, :name, :identifier, :title].include? result
          options[:result] = result
        end

        request.body.rewind
        json_body = JSON.parse request.body.read
        halt 400 unless json_body['values']

        puts json_body['values'].size
        eq_mapping = @api.find_equivalents(namespace, json_body['values'], options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump(eq_mapping)
      end

      get '/namespaces/:namespace/:id/?' do |namespace, value|
        value = @api.find_namespace_value(namespace, value)
        if not value
          halt 404
        end

        render_single(request, value, 'Namespace Value')
      end

      get '/namespaces/:namespace/:id/equivalents/?' do |namespace, value|
        equivalents = @api.find_equivalent(namespace, value)
        if not equivalents or equivalents.empty?
          halt 404
        end

        render_multiple(request, equivalents, "Equivalents for #{namespace} / #{value}")
      end

      get '/namespaces/:namespace/:id/equivalents/:target/?' do |namespace, value, target|
        equivalents = @api.find_equivalent(namespace, value, {
          target: target
        })
        if not equivalents or equivalents.empty?
          halt 404
        end

        render_multiple(request, equivalents, "Equivalents for #{namespace} / #{value} in #{target}")
      end

      get '/namespaces/:namespace/:id/orthologs/?' do |namespace, value|
        orthologs = @api.find_orthologs(namespace, value)
        if not orthologs or orthologs.empty?
          halt 404
        end

        render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value}")
      end

      get '/namespaces/:namespace/:id/orthologs/:target/?' do |namespace, value, target|
        orthologs = @api.find_orthologs(namespace, value, {
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
