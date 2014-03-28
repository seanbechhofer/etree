require 'rubygems'
require 'sqlite3'
require 'getopt/std'
require 'net/http'
require 'json'
require 'yaml'
require 'csv'
require 'open-uri'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'config'
require 'internetarchive'
require 'db'

# Query etree for all performances and store ids in the database.

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

opt = Getopt::Std.getopts("vd")

if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end

HOST = 'www.archive.org'
PATH = '/advancedsearch.php?'
ROWS = '1000'

# construct a URL by concatenating the path with the args
def escape(path, args) 
  first = true
  args.each_key do |k|
    path = path + '&' if (!first)
    path = path + k + '=' + args[k].to_s
    first = false
  end
  return URI.escape(path,'(): ')
end

# build a query string by concatenating together the given selectors/values
def queryString(args) 
  query = ""
  first = true;
  args.each_key do |k|
    query = query + " AND " if (!first)
    query = query + k + ":(" + args[k] + ")" 
    first = false
  end
  return query
end

# construct a query URL using the path and args
def queryURL(host, path, args)
  stuff = {}
  puts escape(path, args) if BEHAVIOUR[:verbose]
  stuff = JSON.parse(open("http://" + host + escape(path, args)).read)
  puts "Found: #{stuff['response']['numFound']}" if BEHAVIOUR[:debug]
  return stuff
end

# Query to IA
q = {
  'mediatype' => 'etree'
}
# Additional information

# Hard coded!
(1..136).each do |page| 
  puts "Page #{page}" if BEHAVIOUR[:verbose]
  args = {
    'q' => queryString(q),
    'page' => page,
    'rows' => ROWS,
    'output' => 'json'
  }
  
  stuff = queryURL(HOST,PATH,args)  
  stuff['response']['docs'].each do |doc|
    entry = InternetArchiveEntry.new(doc)
    # Add the entry to the database
    ins = DATABASE.prepare( "insert or replace into performance (id,date) values (?,?);" )
    ins.execute(entry.identifier,entry.date)
    # Report
    puts entry.identifier if BEHAVIOUR[:debug]
  end
  puts "===================" if BEHAVIOUR[:debug]
end
