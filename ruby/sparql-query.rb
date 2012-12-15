#!/opt/local/bin/ruby
require 'rubygems'
require "net/http"
require "uri"
require 'getopt/std'
require 'json'
require 'yaml'
require 'csv'

$host = "etree.linkedmusic.org"
$port = "80"
$sparql = "/sparql"
# $port = "9091"
# $sparql = "/sparql/"
# $port = "9090"
# $sparql = "/openrdf-sesame/repositories/etree"

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

$data = nil
$op = :nop

opt = Getopt::Std.getopts("q:o:lh:p:s:dv")

if opt["q"] then
  $data = opt["q"]
  $op = :query
end
if opt["o"] then
  $out = opt["o"]
  $op = :query
end
if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end
if opt["h"] then
  $host = opt["h"]
end
if opt["p"] then
  $port = opt["p"]
end
if opt["s"] then
  $sparql = opt["s"]
end

http = Net::HTTP.new($host, $port)        
case
when $op == :query
  puts $data if BEHAVIOUR[:debug]
  $body = IO.read($data)
  puts "Query:" if BEHAVIOUR[:debug]
  puts $body if BEHAVIOUR[:debug]
  response = http.request_post($sparql, 
                               "query=" + $body, 
                               {
                                 'Content-Type' => 'application/x-www-form-urlencoded',
                                 'Accept' => 'application/sparql-results+json'
                               })
  puts "Done" if BEHAVIOUR[:debug]
end
puts response.body if BEHAVIOUR[:debug]
results = JSON.parse(response.body)
vars = results['head']['vars']

if $out then
  csvfile = File.open($out,'w')
  CSV::Writer.generate(csvfile, '|') do |csv|
    csv << vars
    results['results']['bindings'].each do |result|
      line = []
      vars.each do |v|
        if result[v] then
          line << result[v]['value']
        else
          line << "" 
        end
      end
      csv << line
    end
  end
else
  puts results.inspect
end



