#!/usr/bin/env ruby

require 'set'
require 'sinatra/base'
require 'sinatra/reloader'
require 'json'
require_relative 'lib/openbel'

class Namespaces < Sinatra::Base

  storage = OpenBEL::Namespace::SqliteStorage.new 'namespaces.db'

  configure :development do
    require 'perftools'
    require 'rack/perftools_profiler'
    use ::Rack::PerftoolsProfiler, :default_printer => 'callgrind'
    use ::Rack::Deflater

    register Sinatra::Reloader

    SPOKEN_CONTENT_TYPES = %w[application/json text/html text/xml]
  end

  get '/namespaces' do
    ns = storage.namespaces
    if ns.empty?
      halt 404
    end
    
    render_multiple(request, ns.sort { |x,y|
      x.name.to_s <=> y.name.to_s
    }.map(&:to_h))
  end

  get '/namespaces/:namespace' do |ns|
    ns = storage.namespace(ns)
    if ns
      status 200
      render_single(request, ns.to_h)
    else
      status 404
    end
  end

  get '/namespaces/:namespace/all' do |ns|
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

  get '/namespaces/:namespace/:id' do |ns, id|
    statements = storage.info(ns, id)
    if not statements or statements.empty?
      halt 404
    end

    statements.map(&:to_s)
  end

  post '/namespaces/:namespace/canonical-form' do |ns|
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

  post '/namespaces/:namespace/stream-canonical-form' do |ns|
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

  get '/namespaces/:namespace/:id/canonical-form' do |ns, id|
    storage.canonical(ns, id)
  end

  get '/namespaces/:namespace/:id/equivalence' do |ns, id|
    headers 'Content-Type' => 'application/json'
    JSON.unparse storage.equivalences(ns, id)
  end

  get '/namespaces/:namespace/:id/equivalence/:target' do |ns, id, target|
    storage.namespace_equivalence(ns, id, target)
  end

  before do
    unless request.preferred_type(SPOKEN_CONTENT_TYPES)
      halt 406
    end
  end

  helpers do
    def render_single(request, resource)
      case request.preferred_type.to_str
      when 'application/json'
        response.headers['Content-Type'] = 'application/json'
        JSON.unparse hash
      when 'text/html'
        'html'
      when 'text/xml'
        response.headers['Content-Type'] = 'text/xml'
        builder { |xml|
          xml.name hash['name']
          xml.prefix hash['prefix']
        }
      else
        response.headers['Content-Type'] = 'application/json'
        JSON.unparse hash
      end
    end

    def render_multiple(request, resources)
      case request.preferred_type.to_str
      when 'application/json'
        response.headers['Content-Type'] = 'application/json'
        JSON.unparse resources
      when 'text/html'
        'html'
      when 'text/xml'
        response.headers['Content-Type'] = 'text/xml'
        builder { |xml|
          xml.namespaces {
            resources.each do |resource|
              xml.namespace {
                xml.name resource['name']
                xml.prefix resource['prefix']
              }
            end
          }
        }
      else
        response.headers['Content-Type'] = 'application/json'
        JSON.unparse resources
      end
    end

    def make_url(path)
      url(Addressable::URI::encode(path))
    end

    def valid_content_length(request)
      if not request.content_length or request.content_length.to_i <= 0 then
          status 411 # length required
          return false
      end
      true
    end

    def is_json(request)
      if not request.content_type or \
         not request.content_type.include? 'application/json' then
         status 415 # unsupported media type
         return false
      end
      true
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
