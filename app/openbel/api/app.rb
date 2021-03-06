require 'rubygems'

# TODO This should probably be in app-config.rb.
require 'jrjackson'
require 'bel_parser'

require_relative 'util'

require 'rack'
require 'rack/cors'
require 'sinatra/base'
require "sinatra/cookies"

require_relative 'version'
require_relative 'config'
require_relative 'routes/base'
require_relative 'routes/root'
require_relative 'routes/annotations'
require_relative 'routes/authenticate'
require_relative 'routes/datasets'
require_relative 'routes/expressions'
require_relative 'routes/language'
require_relative 'routes/namespaces'
require_relative 'routes/nanopubs'
require_relative 'routes/version'
require_relative 'middleware/auth'

module OpenBEL

  class Server < Sinatra::Application

    configure do
      config = OpenBEL::Config::load!
      OpenBEL.const_set :Settings, config

      tdbdir = OpenBEL::Settings[:resource_rdf][:jena][:tdb_directory]
      BELParser::Resource.default_uri_reader =
        BELParser::Resource::JenaTDBReader.new(tdbdir)
    end

    if OpenBEL::Settings[:auth][:enabled]
      enable :sessions
      set :session_secret, OpenBEL::Settings['session_secret']
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

    # routes not requiring authentication
    use OpenBEL::Routes::Root
    #use OpenBEL::Routes::Version
    use OpenBEL::Routes::Annotations
    use OpenBEL::Routes::Authenticate
    use OpenBEL::Routes::Expressions
    use OpenBEL::Routes::Language
    use OpenBEL::Routes::Namespaces
    use OpenBEL::Routes::Version

    # routes requiring authentication
    if OpenBEL::Settings[:auth][:enabled]
      use OpenBEL::JWTMiddleware::Authentication
    end
    use OpenBEL::Routes::Datasets
    use OpenBEL::Routes::Nanopubs
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
