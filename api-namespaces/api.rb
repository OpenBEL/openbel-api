#!/usr/bin/env ruby

require 'set'
require 'sinatra/base'
require 'sinatra/reloader'
require 'json'
require_relative 'lib/openbel'

class Namespaces < Sinatra::Base
  include OpenBEL::Namespace

  storage = SqliteStorage.new 'namespaces.db'

  configure :development do
    require 'perftools'
    require 'rack/perftools_profiler'
    use ::Rack::PerftoolsProfiler, :default_printer => 'callgrind'
    use ::Rack::Deflater

    register Sinatra::Reloader

    SPOKEN_CONTENT_TYPES = %w[application/json text/html text/xml]
  end

  get '/namespaces/?' do
    ns = storage.namespaces
    if ns.empty?
      halt 404
    end
    
    render_multiple(request, ns.sort { |x,y|
      x.prefLabel.to_s <=> y.prefLabel.to_s
    }, 'All Namespaces')
  end

  get '/namespaces/:namespace/?' do |ns|
    ns = storage.namespace(ns)
    if ns
      status 200
      render_single(request, ns, 'Namespace')
    else
      status 404
    end
  end

  get '/namespaces/:namespace/all/?' do |ns|
    status 200
    stream do |out|
      scheme_pattern = {predicate: URI('http://www.w3.org/2004/02/skos/core#inScheme')}
      proxy.each(scheme_pattern) do |trpl|
        subject_uri = trpl.subject.uri
        proxy.each({
          subject: subject_uri,
          predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel')}) do |label|
          out << label.object.to_s + "\n"
        end
      end
    end
  end

  get '/namespaces/:namespace/:id/?' do |ns, id|
    value = storage.info(ns, id)
    if not value
      halt 404
    end

    render_single(request, value, 'Namespace Value')
  end

  post '/namespaces/:namespace/canonical-form/?' do |ns|
    request.body.rewind
    body = request.body.read

    if body.empty?
      halt 400
    end

    headers 'Content-Type' => 'application/json'
    fx = storage.method(:canonical).to_proc.curry.call(ns)
    json_body = JSON.parse body
    JSON.unparse json_body.map { |x| fx.call(x) }
  end

  post '/namespaces/:namespace/stream-canonical-form/?' do |ns|
    request.body.rewind
    body = request.body.read

    if body.empty?
      halt 400
    end

    status 200
    stream do |out|
      json_body = JSON.parse body
      fx = storage.method(:canonical).to_proc.curry.call(ns)
      json_body.each do |value|
        out << JSON.unparse(fx.call(value))
      end
    end
  end

  get '/namespaces/:namespace/:id/canonical-form/?' do |ns, id|
    storage.canonical(ns, id)
  end

  get '/namespaces/:namespace/:id/equivalences/?' do |ns, id|
    equivalences = storage.equivalences(ns, id)
    if equivalences.empty?
      halt 404
    end
    
    render_multiple(request, equivalences.sort { |x,y|
      x.prefLabel.to_s <=> y.prefLabel.to_s
    }, "Equivalences for #{ns} / #{id}")
  end

  get '/namespaces/:namespace/:id/equivalence/:target/?' do |ns, id, target|
    storage.namespace_equivalence(ns, id, target)
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
        puts resource.class
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
