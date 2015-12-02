Gem::Specification.new do |spec|
  spec.name                  = 'openbel-api'
  spec.version               = '0.2.0'
  spec.summary               = %q{The OpenBEL API provided over RESTful HTTP endpoints.}
  spec.description           = %q{The OpenBEL API provides a RESTful API over HTTP to manage BEL knowledge.}
  spec.license               = 'Apache-2.0'
  spec.authors               = [
                                 'Anthony Bargnesi',
                                 'Nick Bargnesi',
                                 'William Hayes'
                               ]
  spec.date                  = %q{2015-12-02}
  spec.email                 = %q{abargnesi@selventa.com}
  spec.files                 = Dir.glob('lib/**/*.rb') << 'LICENSE'
  spec.executables           = Dir.glob('bin/*').map(&File.method(:basename))
  spec.homepage              = 'https://github.com/OpenBEL/openbel-server'
  spec.require_paths         = ['lib']
  spec.platform              = 'java'
  spec.required_ruby_version = '>= 2.0.0'
end
# vim: ts=2 sw=2:
# encoding: utf-8
