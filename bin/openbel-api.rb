#!/usr/bin/env jruby
require 'puma/cli'

ROOT = File.expand_path('..', File.dirname(__FILE__))

cli = Puma::CLI.new([
  '-C',
  File.join(ROOT, 'config', 'server_config.rb'),
  File.join(ROOT, 'app', 'openbel', 'api', 'config.ru')
])
begin
  cli.run
rescue => e
  STDERR.puts e.message
  exit 1
end
