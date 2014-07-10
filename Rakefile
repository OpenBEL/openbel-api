HOST = "localhost"
PORT = 3000

task :routes do
  require_relative 'tests/lib/test_helper'
  TestHelper.using_api HOST, PORT do
    system("bundle exec tests/profile_routes.rb #{HOST} #{PORT}")
  end
end

task :run_rdf do
  require_relative 'app/config'
  ENV[OpenBEL::Config::CFG_VAR] = 'tests/config/rdf-config.yml'
  Rake::Task["routes"].invoke
end

task :run_cache do
  require_relative 'app/config'
  ENV[OpenBEL::Config::CFG_VAR] = 'tests/config/cache-config.yml'
  Rake::Task["routes"].invoke
end
