HOST = "localhost"
PORT = 3000

task :routes do |args|
  require 'net/http'
  system("thin --daemonize --log /tmp/routes.log --pid thin.pid start")

  alive = nil
  5.times do
    begin
      res = Net::HTTP.get_response(URI("http://#{HOST}:#{PORT}/namespaces"))
      if res.is_a?(Net::HTTPSuccess)
        alive = true
        break
      end
    rescue; end
    sleep 1
  end
  fail(RuntimeError, "Count not connect to #{HOST}:#{PORT}") unless alive

  system("bundle exec tests/profile_routes.rb #{HOST} #{PORT}")
  Process.kill 'INT', File.read("thin.pid").to_i
  sleep 2
end
