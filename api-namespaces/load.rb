#!/usr/bin/env ruby

require 'optparse'
require 'redlander'
require 'uri'

# defaults
options = {
  new: 'no',
  name: 'default_db'
}
OptionParser.new do |opts|
  opts.banner = "Usage: load.rb [name] [files...]"
  opts.on('-f', '--file FILE', 'RDF data to load.') do |f|
    (options[:files] ||= []) << ('file://' + f.to_s)
  end
  opts.on("-n", "--name NAME", "Storage name") do |name|
    options[:name] = name
  end
  opts.on("-w", "--new", "New storage") do
    options[:new] = 'yes'
  end
  opts.on("-d", "--debug", "Debug") do
    options[:debug] = true
  end
end.parse!

unless options[:files]
  $stderr.write("An rdf file is required.\n");
  exit 1
end

if options[:new] != 'yes' and not File.exist? options[:name]
  options[:new] = 'yes'
end
  

def which_parser(file)
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

model = Redlander::Model.new(
  new: options[:new],
  name: options[:name],
  storage: 'sqlite',
  synchronous: 'off')

# XXX can we be database agnostic here? DBI module or something?
if options[:new] == 'yes'
  require 'sqlite3'
  db = SQLite3::Database.new options[:name]
  begin
    db.execute('create index literals_text_index on literals(text);')
    db.execute('create index triples_pou_index on triples(predicateUri, objectUri);')
    db.execute('create index triples_spou_index on triples(subjectUri, predicateUri, objectUri);')
    db.execute('create index triples_spol_index on triples(subjectUri, predicateUri, objectLiteral);')
  ensure
    db.close
  end
end

model = Redlander::Model.new(
  new: 'no',
  name: options[:name],
  storage: 'sqlite',
  synchronous: 'off')

if options[:files]
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
end
# vim: ts=2 sw=2
