Gem::Specification.new do |spec|
  spec.name                  = 'openbel-server'
  spec.version               = '0.1.0'
  spec.summary               = %q{The OpenBEL API.}
  spec.description           = %q{The OpenBEL API manages BEL data.}
  spec.license               = 'Apache-2.0'
  spec.authors               = ['Anthony Bargnesi']
  spec.date                  = %q{2014-07-17}
  spec.email                 = %q{abargnesi@selventa.com}
  spec.files                 = Dir.glob('lib/**/*.rb') << 'LICENSE'
  spec.executables           = Dir.glob('bin/*').map(&File.method(:basename))
  spec.homepage              = 'https://github.com/OpenBEL/openbel-server'
  spec.require_paths         = ["lib"]
  spec.required_ruby_version = '>= 1.9.3'
end
# vim: ts=2 sw=2:
# encoding: utf-8
