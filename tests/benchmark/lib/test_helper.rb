require 'net/http'

module TestHelper

  def self.using_api(host, port)
    system("thin --daemonize --trace --log /tmp/routes.log --pid thin.pid start")

    alive = nil
    5.times do
      begin
        res = Net::HTTP.get_response(URI("http://#{host}:#{port}/namespaces"))
        if res.is_a?(Net::HTTPSuccess)
          alive = true
          break
        end
      rescue; end
      sleep 1
    end
    fail(RuntimeError, "Count not connect to #{host}:#{port}") unless alive

    yield

    Process.kill 'INT', File.read("thin.pid").to_i
    sleep 2
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
