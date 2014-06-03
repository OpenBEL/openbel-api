#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'benchmark'

include Net

HOST = ARGV[0] || 'localhost'
PORT = ARGV[1] || 3000

def api_uri(path, query)
  uri = URI("http://#{HOST}:#{PORT}")
  uri.path = path
  uri.query = query if query
  uri
end

File.open('1000') do |f|
  EQ_VALUE_1000 = f.readlines.map {|x| "value=#{URI.encode(x.chomp)}" }.join('&')
end

API_CALLS = [
  api_uri('/namespaces', nil),
  api_uri('/namespaces/hgnc', nil),
  api_uri('/namespaces/hgnc/391', nil),
  api_uri('/namespaces/hgnc/AKT1', nil),
  api_uri("/namespaces/hgnc/#{URI.encode('v-akt murine thymoma viral oncogene homolog 1')}", nil),
  api_uri('/namespaces/hgnc/AKT1/equivalents', nil),
  api_uri('/namespaces/hgnc/AKT1/orthologs', nil),
  api_uri("/namespaces/hgnc/equivalents", "result=name&namespace=egid&#{EQ_VALUE_1000}"),
  api_uri("/namespaces/hgnc/equivalents", "result=resource&namespace=egid&#{EQ_VALUE_1000}")
]

API_CALLS.each do |api_call|
  Benchmark.bm(80) do |x|
    x.report(api_call.path + (api_call.query ? "?#{api_call.query.to_s[0..45]}" : '')) {
      response = HTTP.get_response(api_call)
      code = response.code
      if code != "200"
        fail "Error #{code} for #{api_call.path}."
      end
      body = response.read_body
      if body.size <= 0
        fail "Response body is empty for #{api_call.path}."
      end
    }
  end
end
