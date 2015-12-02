source 'https://rubygems.org'

# BEL.rb
gem 'bel',                     '~> 0.4.0.beta'
gem 'bel-search-sqlite',       '0.4.0.beta1', :platforms => :jruby
gem 'bel-rdf-jena',            '0.4.0.beta1', :platforms => :jruby
gem 'rdf',                     '1.99.0'
gem 'addressable',             '~> 2.3'
gem 'uuid',                    '~> 2.3'

# Mongo
gem 'mongo',                   '~> 1.12'

# JSON
gem 'multi_json',              '~> 1.10'
gem 'jrjackson',               '~> 0.2',  :platforms => :jruby
gem 'oj',                      '~> 2.10', :platforms => [:ruby, :rbx]
gem 'json_schema'

# XML
gem 'nokogiri'

# Web
gem 'oat'
gem 'puma',                    '~> 2.14'
gem 'rack'
gem 'rack-cors'
gem 'rack-handlers'
gem 'sinatra'
gem 'sinatra-advanced-routes',            :require => 'sinatra/advanced_routes'
gem 'sinatra-contrib'

# Cannot use on JRuby
# gem 'bson_ext',                '~> 1.12'

# Unused
# gem 'redlander'
# gem 'kyotocabinet-ffi'
# gem 'builder'
# gem 'dot_hash'

group :test do
  gem 'faraday_middleware'
  gem 'hyperclient'
  gem 'rantly',            '~> 0.3'
  gem 'rspec'
end

group :development do
  gem 'POpen4'
  gem 'pry'
end
# vim: ts=2 sw=2
