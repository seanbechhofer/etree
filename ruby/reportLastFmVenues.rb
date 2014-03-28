require 'rubygems'
require "net/http"
require "uri"
require 'getopt/std'
require 'json'
require 'yaml'
require 'csv'
require 'rexml/document'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'last-fm'

# Query for last fm venues

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

$data = nil
$op = :nop

opt = Getopt::Std.getopts("q:o:dvh")

if opt["q"] then
  $query = opt["q"]
  $op = :query
end
if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end
if opt["h"] then
  puts "[-q query]"
  exit
end

if $op == :query then
  venues = last_fm_venue_query($query)
  puts "#{venues.size} venues"
  venues.each do |venue|
    puts venue.inspect
  end
end
