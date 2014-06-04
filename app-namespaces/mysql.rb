#!/usr/bin/env ruby

require 'optparse'
require 'redlander'
require 'uri'

def which_parser(file)
  puts file[file.rindex('.')..-1]
  case
  when file.end_with?('.nt')
    'ntriples'
  when file.end_with?('.nq')
    'nquads'
  when file.end_with?('ttl')
    'turtle'
  when ['.rdfxml', '.xml'].include?(file[file.rindex('.')..-1])
    'rdfxml'
  else
    'guess'
  end
end

def make_model(options, new = nil)
  if options['type'] == 'mysql'
    Redlander::Model.new(
      storage: 'mysql',
      host: 'localhost',
      port: '3306',
      database: 'rdf',
      user: 'root',
      password: '',
      new: new != nil ? nil : options[:new],
      name: options[:name],
      synchronous: 'off')
  elsif options['type'] == 'sqlite'
    Redlander::Model.new(
      new: new != nil ? nil : options[:new],
      name: options[:name],
      storage: 'sqlite',
      synchronous: 'off')
  else
    raise ArgumentError, "Cannot create storage type #{options['type']}"
  end
end

# defaults
options = {
  name: 'default_db',
  type: 'sqlite',
  new: 'no',
  files: [],
  debug: false
}
OptionParser.new do |opts|
  opts.banner = "Usage: load.rb [name] [files...]"
  opts.on("-n", "--name NAME", "Storage name") do |name|
    options[:name] = name
  end
  opts.on("-t", "--type TYPE", "Storage type (mysql, sqlite)") do |type|
    options[:type] = type
  end
  opts.on("-w", "--new", "New storage") do
    options[:new] = 'yes'
  end
  opts.on('-f', '--file FILE', 'RDF data to load.') do |f|
    (options[:files] ||= []) << ('file://' + f.to_s)
  end
  opts.on("-d", "--debug", "Debug") do
    options[:debug] = true
  end
end.parse!
options[:debug] && $stdout.puts("Configured as:\n#{options}")

model = make_model(options)
if options[:new] == 'yes'
  require 'mysql'
  m = Mysql.init
  m = Mysql.real_connect('localhost', 'root', '', 'rdf', 3306, nil, nil)
  begin
    m.query("select ID from Models where Name = '#{options[:name]}'") do |res|
      statement_table = "Statements#{res.fetch_row[0]}"
      m.query("create index SubjectPredicateObject on #{statement_table} (Subject, Predicate, Object)")
      m.query("create index Uri on Resources (URI(256))")
      m.query("create index BnodeName on Bnodes (Name(256))")
    end
  ensure
    m.close
  end
end

options[:files].each do |path|
  parser = which_parser(path)

  options[:debug] && $stdout.puts("Loading #{path} (parser - #{parser}).")
  model.transaction_start!
  begin
    model.from(URI(path), format: parser)
  ensure
    model.transaction_commit!
  end
end
# vim: ts=2 sw=2
