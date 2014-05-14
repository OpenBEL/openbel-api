#!/usr/bin/env ruby

require 'rack'
require 'set'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'json'
require_relative 'lib/openbel'

class Namespaces < Sinatra::Base
  include OpenBEL::Namespace

  register Sinatra::ConfigFile
  config_file 'config.yml'

  def initialize
    super
    require './lib/storage/redlander.rb'
    @api = API.new StorageRedlander.new(settings.storage)
  end

  configure :development do
    require 'perftools'
    require 'rack/perftools_profiler'
    use ::Rack::PerftoolsProfiler, :default_printer => 'callgrind'
    use ::Rack::Deflater

    register Sinatra::Reloader

    SPOKEN_CONTENT_TYPES = %w[application/json text/html text/xml]
  end

  get '/namespaces/?' do
    namespaces = @api.find_namespaces
    if namespaces.empty?
      halt 404
    end
    
    render_multiple(request, namespaces.sort { |x,y|
      x.prefLabel.to_s <=> y.prefLabel.to_s
    }, 'All Namespaces')
  end

  get '/namespaces/:namespace/?' do |namespace|
    ns = @api.find_namespace(namespace)
    if ns
      status 200
      render_single(request, ns, 'Namespace')
    else
      status 404
    end
  end

  post '/namespaces/:namespace/equivalences/?' do |namespace|
    unless request.media_type == 'application/json'
      halt 400
    end

    request.body.rewind
    json_body = JSON.parse request.body.read
    halt 400 unless json_body['values']
    matches = @api.find_equivalences(namespace, json_body['values'])
    
    response.headers['Content-Type'] = 'application/json'
    JSON.dump(matches, response)
  end

  post '/namespaces/:namespace/equivalences/:target/?' do |namespace, target|
    unless request.media_type == 'application/json'
      halt 400
    end

    request.body.rewind
    json_body = JSON.parse request.body.read
    halt 400 unless json_body['values']
    matches = @api.find_equivalences(namespace, json_body['values'], {
      target: target
    })
    
    response.headers['Content-Type'] = 'application/json'
    JSON.dump(matches, response)
  end

  get '/namespaces/:namespace/:id/?' do |namespace, value|
    value = @api.find_namespace_value(namespace, value)
    if not value
      halt 404
    end

    render_single(request, value, 'Namespace Value')
  end

  get '/namespaces/:namespace/:id/equivalences/?' do |namespace, value|
    equivalences = @api.find_equivalence(namespace, value)
    if equivalences.empty?
      halt 404
    end
    
    render_multiple(request, equivalences, "Equivalences for #{namespace} / #{value}")
  end

  get '/namespaces/:namespace/:id/equivalences/:target/?' do |namespace, value, target|
    equivalences = @api.find_equivalence(namespace, value, {
      target: target
    })
    if equivalences.empty?
      halt 404
    end
    
    render_multiple(request, equivalences, "Equivalences for #{namespace} / #{value} in #{target}")
  end

  get '/namespaces/:namespace/:id/orthologs/?' do |namespace, value|
    orthologs = @api.find_orthology(namespace, value)
    if orthologs.empty?
      halt 404
    end
    
    render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value}")
  end

  get '/namespaces/:namespace/:id/orthologs/:target/?' do |namespace, value, target|
    orthologs = @api.find_orthology(namespace, value, {
      target: target
    })
    if orthologs.empty?
      halt 404
    end
    
    render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value} in #{target}")
  end

  before do
    unless request.preferred_type(SPOKEN_CONTENT_TYPES)
      halt 406
    end
  end

  helpers do

    def resolve_supported_content_type(request)
      preferred = request.preferred_type.to_str
      if preferred == '*/*'
        'application/json'
      else
        preferred
      end
    end

    def render_single(request, obj, title)
      content_type = resolve_supported_content_type(request)
      resource = OpenBEL::Namespace.resource_for(obj, content_type)
      case content_type
      when 'application/json'
        response.headers['Content-Type'] = 'application/json'
        resource.to_json(base_url: request.base_url, url: request.url)
      when 'text/html'
        response.headers['Content-Type'] = 'text/html'
        obj_doc = Nokogiri::HTML.parse(File.open('views/obj.html'))
        resource.to_html(obj_doc, title,
          base_url: request.base_url,
          url: request.url)
      when 'text/xml'
        response.headers['Content-Type'] = 'text/xml'
        resource.to_xml(base_url: request.base_url, url: request.url)
      end
    end

    def render_multiple(request, obj, title)
      content_type = resolve_supported_content_type(request)
      resource = OpenBEL::Namespace.resource_for(obj, content_type)
      case content_type
      when 'text/html'
        response.headers['Content-Type'] = 'text/html'
        obj_doc = Nokogiri::HTML.parse(File.open('views/obj.html'))
        resource.to_html(obj_doc, title,
          base_url: request.base_url,
          url: request.url)
      when 'text/xml'
        response.headers['Content-Type'] = 'text/xml'
        resource.to_xml(base_url: request.base_url, url: request.url)
      else
        response.headers['Content-Type'] = 'application/json'
        resource.to_json(base_url: request.base_url, url: request.url)
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
