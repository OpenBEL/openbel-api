require 'rubygems'
require 'bundler'

Bundler.setup
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

# TODO This should probably be in app-config.rb.
require 'jrjackson'

require 'config/config'
require 'app/util'

require 'rack/cors'

require 'sinatra/base'
require 'app/routes/base'
require 'app/routes/root'
require 'app/routes/annotations'
require 'app/routes/evidence'
require 'app/routes/expressions'
require 'app/routes/functions'
require 'app/routes/namespaces'

module OpenBEL

  class Server < Sinatra::Application

    configure :development do
      # pass
    end

    configure do
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

    use OpenBEL::Routes::Root
    use OpenBEL::Routes::Annotations
    use OpenBEL::Routes::Evidence
    use OpenBEL::Routes::Expressions
    use OpenBEL::Routes::Functions
    use OpenBEL::Routes::Namespaces
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
