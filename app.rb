require 'rubygems'
require 'bundler'

Bundler.require
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

require 'app/util'
require 'app/routes/base'
require 'app/routes/bel'
require 'app/routes/namespaces'

module OpenBEL

  class Server < Sinatra::Application

    use Rack::Deflater
    use OpenBEL::Routes::Namespaces
    use OpenBEL::Routes::BEL

    configure :development do
      require 'perftools'
      require 'rack/perftools_profiler'
      use ::Rack::PerftoolsProfiler, :default_printer => 'text'

    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
