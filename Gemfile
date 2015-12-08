source 'https://rubygems.org'

# TODO More version specifiers so dependencies don't vary much.

# BEL.rb
gem 'bel',                     '~> 0.4.0.beta'
gem 'bel-search-sqlite',       '0.4.0.beta1', :platforms => :jruby
gem 'bel-rdf-jena',            '0.4.0.beta1', :platforms => :jruby
gem 'rdf',                     '1.99.0'
gem 'addressable',             '~> 2.3'
gem 'uuid',                    '~> 2.3'

# Mongo
gem 'mongo',                   '~> 1.12'
gem 'bson',                    '~> 1.12'
#gem 'em-mongo',                :git => 'https://github.com/fl00r/em-mongo.git'

# JSON
gem 'multi_json',              '~> 1.10'
gem 'jrjackson',               '~> 0.3',  :platforms => :jruby
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

group :test do
  gem 'faraday_middleware'
  gem 'hyperclient'
  gem 'rantly',            '~> 0.3'
  gem 'rspec'
end

group :development do
  gem 'POpen4'
  gem 'pry'
  gem 'pry-doc'
  gem 'ruby-debug'
  gem 'ruby-debug-base'
  gem 'ruby-debug-ide'
end
# vim: ts=2 sw=2
