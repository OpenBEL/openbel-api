#!/usr/bin/env ruby
require 'sinatra/advanced_routes'
require_relative 'lib/siege'
require_relative '../app.rb'
require_relative '../app/routes/namespaces.rb'

unless ARGV.length == 2
  $stderr.puts "usage: profile_routes.rb <host> <port>"
  exit 1
end

HOST = ARGV[0]
PORT = ARGV[1].to_i

if PORT.zero?
  $stderr.puts "error: port is invalid"
  exit 1
end

SiegeTank.on_routes(OpenBEL::Routes::Namespaces, HOST, PORT, true, 10) do |path_examples|
  path_examples << { :namespace => 'hgnc', :id => '391', :target => 'egid' }
  path_examples << { :namespace => 'hgnc-human-genes', :id => 'AKT1', :target => 'sp' }
  path_examples << { :namespace => 'Hgnc Human Genes', :id => 'AKT1', :target => 'sp' }
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
