require 'rubygems'
require 'bundler'

Bundler.setup
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

require 'config/config'
require 'app/util'

require 'sinatra/base'
require 'app/routes/base'
require 'app/routes/bel'
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

    if OpenBEL::Settings["namespace-api"]
      require 'app/routes/namespaces'
      use OpenBEL::Routes::Namespaces
    end
    use OpenBEL::Routes::BELApp
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
