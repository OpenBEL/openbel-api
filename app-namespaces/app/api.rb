require 'rack'
require 'set'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'json'
require 'cgi'

require_relative 'util'
require_relative OpenBEL::Util::path(File.dirname(__FILE__), '..', 'lib', 'openbel')
require_relative OpenBEL::Util::path(File.dirname(__FILE__), '..', 'lib', 'storage', 'redlander')

# App
class Namespaces < Sinatra::Base
  include OpenBEL::Namespace

  register Sinatra::ConfigFile
  config_file "#{OPENBEL_ROOT}/config.yml"

  def initialize
    super
    @api = API.new StorageRedlander.new(settings.storage)
  end

  configure :development do
    require 'perftools'
    require 'rack/perftools_profiler'
    use ::Rack::PerftoolsProfiler, :default_printer => 'text'
    use ::Rack::Deflater

    SPOKEN_CONTENT_TYPES = %w[application/json text/html text/xml]
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

    value_equivalence = @api.find_equivalents(namespace, values, options)
    render_multiple(request, value_equivalence, "Multiple equivalence for #{namespace} values")
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
