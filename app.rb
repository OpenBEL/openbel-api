require 'rubygems'
require 'bundler'

Bundler.setup
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

require 'app/config'
require 'app/util'

require 'sinatra/base'
require 'app/routes/base'
require 'app/routes/bel'
require 'app/routes/namespaces'

module OpenBEL

  class Server < Sinatra::Application
    include DotHash

    configure :development do
      require 'perftools'
      require 'pry'
      require 'rack/perftools_profiler'
      use ::Rack::PerftoolsProfiler, :default_printer => 'text'
    end

    configure do
      config = Config::load! do |failure|
        $stderr.puts failure
        exit!
      end
      OpenBEL.const_set :Settings, config
    end

    use Rack::Deflater

    if OpenBEL::Settings.namespace == true
      require 'app/routes/namespaces'
      use OpenBEL::Routes::Namespaces
    end
    use OpenBEL::Routes::BEL
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
