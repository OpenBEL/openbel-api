require 'rubygems'

# TODO This should probably be in app-config.rb.
require 'jrjackson'

require_relative 'util'

require 'rack/cors'
require 'sinatra/base'
require "sinatra/cookies"

require_relative 'version'
require_relative 'config'
require_relative 'routes/base'
require_relative 'routes/root'
require_relative 'routes/annotations'
require_relative 'routes/nanopub'
require_relative 'routes/datasets'
require_relative 'routes/expressions'
require_relative 'routes/language'
require_relative 'routes/functions'
require_relative 'routes/relationships'
require_relative 'routes/namespaces'
require_relative 'routes/authenticate'
require_relative 'routes/version'
require_relative 'middleware/auth'

module OpenBEL

  class Server < Sinatra::Application

    configure do
      config = OpenBEL::Config::load!
      OpenBEL.const_set :Settings, config
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
    use OpenBEL::Routes::Version
    use OpenBEL::Routes::Annotations
    use OpenBEL::Routes::Expressions
    use OpenBEL::Routes::Language
    use OpenBEL::Routes::Functions
    use OpenBEL::Routes::Relationships
    use OpenBEL::Routes::Namespaces
    use OpenBEL::Routes::Authenticate

    # routes requiring authentication
    if OpenBEL::Settings[:auth][:enabled]
      use OpenBEL::JWTMiddleware::Authentication
    end
    use OpenBEL::Routes::Datasets
    use OpenBEL::Routes::Nanopub
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
