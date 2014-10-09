#!/usr/bin/env ruby

# Using the following set RUBYOPT to "-rbundler/setup.rb" which
# causes a 'bundle' subprocess to invoke bundler again...the effect
# is that git gems can no longer be found when packaging to vendor/cache.
#
require 'rubygems'
require 'bundler'
Bundler.setup

require 'term/ansicolor'
require_relative 'tools'

Dir.chdir File.join(File.expand_path('..', __FILE__), '..', '..')
load 'env.rb'

Color = Object.new.extend Term::ANSIColor

puts Color.yellow { "! Bundling gem files into vendor/cache." }
Bundler.with_clean_env {
  OpenBEL::Tools.sh!('bundle package --all')
}

(ret, sha) = OpenBEL::Tools.sh('git rev-parse HEAD')
sha = sha[0, 8]
if ret.nonzero?
  $stderr.write "Failed to retrieve git commit sha."
end

if ! Dir.exist?(ENV['OB_DISTRIBUTION_DIR'])
  puts Color.green { "! Creating directory #{ENV['OB_DISTRIBUTION_DIR']}" }
  Dir.mkdir ENV['OB_DISTRIBUTION_DIR']
end

tar_cmd = %Q{
  tar zcf "#{ENV['OB_DISTRIBUTION_DIR']}/openbel-server-#{sha}.tar.gz"
  -C "#{Dir.pwd}" .
  --exclude "*.db"
  --exclude "*.tar.gz"
  --exclude "\.git/*"
  --exclude "vendor/ruby*"
  --exclude "vendor/bundle*"
  --exclude ".bundle"
}.gsub(/\n/, '').squeeze(' ')
OpenBEL::Tools.sh!(tar_cmd)
