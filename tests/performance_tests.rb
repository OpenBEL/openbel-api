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

File.open('5000') do |f|
  EQ_VALUE_5000 = f.readlines.map {|x| "value=#{URI.encode(x.chomp)}" }.join('&')
end

API_CALLS = [
  ['All namespaces', api_uri('/namespaces', nil)],
  ['Namespace', api_uri('/namespaces/hgnc', nil)],
  ['Value by identifier', api_uri('/namespaces/hgnc/391', nil)],
  ['Value by name', api_uri('/namespaces/hgnc/AKT1', nil)],
  ['Value by title', api_uri("/namespaces/hgnc/#{URI.encode('v-akt murine thymoma viral oncogene homolog 1')}", nil)],
  ['Equivalents for value (by identifier)', api_uri('/namespaces/hgnc/391/equivalents', nil)],
  ['Equivalents for value (by name)', api_uri('/namespaces/hgnc/AKT1/equivalents', nil)],
  ['Equivalents for value (by title)', api_uri("/namespaces/hgnc/#{URI.encode('v-akt murine thymoma viral oncogene homolog 1')}/equivalents", nil)],
  ['Orthologs for value (by identifier)', api_uri("/namespaces/hgnc/391/orthologs", nil)],
  ['Orthologs for value (by name)', api_uri("/namespaces/hgnc/AKT1/orthologs", nil)],
  ['Orthologs for value (by title)', api_uri("/namespaces/hgnc/#{URI.encode('v-akt murine thymoma viral oncogene homolog 1')}/orthologs", nil)],
  ['Equivalent names within namespaces (1000)', api_uri("/namespaces/hgnc/equivalents", "result=name&namespace=egid&#{EQ_VALUE_1000}")],
  ['Equivalent resources within namespaces (1000)', api_uri("/namespaces/hgnc/equivalents", "result=resource&namespace=egid&#{EQ_VALUE_1000}")],
  ['Equivalent names within namespaces (5000)', api_uri("/namespaces/hgnc/equivalents", "result=name&namespace=egid&#{EQ_VALUE_5000}")],
  ['Equivalent resources within namespaces (5000)', api_uri("/namespaces/hgnc/equivalents", "result=resource&namespace=egid&#{EQ_VALUE_5000}")]
]

API_CALLS.each do |api_call|
  (name, uri) = api_call
  Benchmark.bm(80) do |x|
    x.report(name) {
      response = HTTP.get_response(uri)
      code = response.code
      if code != "200"
        fail "Error #{code} for #{uri.path}."
      end
      body = response.read_body
      if body.size <= 0
        fail "Response body is empty for #{uri.path}."
      end
    }
  end
end
