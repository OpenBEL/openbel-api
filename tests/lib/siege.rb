require 'pry'
require 'uri'
require 'net/http'
require 'benchmark'
require 'term/ansicolor'

module SiegeTank

  def self.on_routes(app, host, port, random_examples = true, samples = 100)
    fail ArgumentError, "app is nil" unless app

    path_examples = []
    yield path_examples

    app.each_route.find_all { |route| route.verb == 'GET' }.each do |route|
      ex = self.find_example(route.path, path_examples, random_examples)
      fail RuntimeError, "No relevant example for #{route.path}" unless ex

      request_path("http://#{host}:#{port}#{make_path(route.path, ex)}", samples)
    end
  end

  private

  Color = Object.new.extend Term::ANSIColor

  def self.find_example(path, examples, random = true)
    path_variables = path.scan(%r{/:([a-z]+)/}).flatten.map(&:to_sym)
    (random ? examples.shuffle : examples).find { |ex|
      path_variables.all? { |var| ex.include? var }
    }
  end

  def self.make_path(path, example)
    example.keys.reduce(path) { |acc, key|
      acc.sub ":#{key}", example[key]
    }.chomp('?')
  end

  def self.request_path(uri, samples = 100)
    response = Net::HTTP.get_response(URI(URI.encode(uri)))
    uri_display = Color.green { uri }
    status_display = response.code == "200" ?
      Color.green { response.code } :
      Color.red { response.code }
    puts "#{uri_display} ( #{status_display} )"
    Benchmark.benchmark(Benchmark::CAPTION, 7, Benchmark::FORMAT, "TOTAL:", "AVG:") do |bm|
      results = []
      samples.times {
        results << Benchmark.measure { Net::HTTP.get_response(URI(URI.encode(uri))) }
      }
      [results.reduce(&:+), (results.reduce(&:+)) / samples]
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
