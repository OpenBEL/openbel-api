Dir.chdir File.expand_path('../../..', __FILE__)

if File.exists? 'env_custom.rb'
  load 'env_custom.rb'
end

# -- Configuration --
ENV['OB_RUBY_VERSION'] ||= File.read('.ruby-version')
# -- Locations --
ENV['OB_DISTRIBUTION_DIR'] ||= File.join(Dir.pwd, 'distribution')
# vim: ts=2 sts=2 sw=2
