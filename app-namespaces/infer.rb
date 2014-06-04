#!/usr/bin/env ruby

require 'digest'
require 'optparse'
require 'pathname'
require 'redlander'
require 'tmpdir'
require './rule'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: infer.rb [name]"
  opts.on("-n", "--name NAME", "Storage name") do |name|
    options[:name] = name
  end
  opts.on("-d", "--debug", "Debug") do
    options[:debug] = true
  end
end.parse!

unless options[:name]
  $stderr.write("The storage name is required.\n");
  exit 1
end

include Redlander

SCHEMA_URI = URI("file://#{Pathname(Dir.pwd) + 'schema.nt'}")

base = Model.new({
  storage: 'sqlite',
  name: options[:name],
  synchronous: 'off'
})

RULES.each do |name, construct|
  file_path = Pathname(Dir.tmpdir) + "#{name}_load.nt"

  # write out
  puts "running #{name} inference (saved to #{file_path})"
  File.open(file_path, "w") do |f|
    base.query(construct) do |stmt|
      f << (stmt.to_s + " .\n")
    end
  end

  # read in to new model
  puts "creating #{name} model"
  rule_model = Model.new({
    storage: "sqlite",
    name: "#{name}.db",
    new: "yes",
    synchronous: "off"
  })
  rule_model.from URI("file://#{file_path}"), format: 'ntriples'

  # merge into base
  puts "merging #{name} model into base"
  base.merge(rule_model)
end
# vim: ts=2 sw=2
# encoding: utf-8
