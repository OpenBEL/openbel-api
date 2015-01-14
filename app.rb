require 'rubygems'
require 'bundler'

Bundler.setup
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

require 'config/config'
require 'app/util'

require 'rack/cors'

require 'sinatra/base'
require 'app/routes/base'
require 'app/routes/completions'
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
        resource '/bel/*'
        resource '/namespaces/*'
      end
    end
    disable :protection

    use OpenBEL::Routes::Completions
    use OpenBEL::Routes::Functions
    use OpenBEL::Routes::Namespaces
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
