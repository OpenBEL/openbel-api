source 'https://rubygems.org'

def at_root(relative_path)
  File.join(
    File.expand_path(File.dirname(__FILE__)),
    relative_path
  )
end

# Fetch dependencies from gemspec
gemspec

# Reference local openbel platform projects.
gem 'bel_parser',        path: at_root('./subprojects/bel_parser'),        platforms: :jruby
gem 'bel',               path: at_root('./subprojects/bel'),               platforms: :jruby
gem 'bel-rdf-jena',      path: at_root('./subprojects/bel-rdf-jena'),      platforms: :jruby
gem 'bel-search-sqlite', path: at_root('./subprojects/bel-search-sqlite'), platforms: :jruby
