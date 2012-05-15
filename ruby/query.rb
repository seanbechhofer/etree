require 'rubygems'
require 'net/http'
require 'json'
require 'internetarchive'
require 'yaml'
require 'csv'

RESPONSE = "response.txt"
DATA = "data"
DEBUG = false

HOST = 'www.archive.org'
PATH = '/advancedsearch.php?'
ROWS = '1'

$data = []

# construct a URL by concatenating the path with the args
def escape(path, args) 
  first = true
  args.each_key do |k|
    path = path + '&' if (!first)
    path = path + k + '=' + args[k]
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
  Net::HTTP.start(host) do |http|
    puts escape(path, args) if DEBUG
    response = http.get(escape(path, args))
    File.open(RESPONSE,'w') do |f|
      f.puts response.body
    end
    
    #  puts response
    stuff = JSON.parse(response.body)
    puts "Found: #{stuff['response']['numFound']}" if DEBUG
  end
  return stuff
end

# Query to IA
q = {
  'mediatype' => 'etree'
}
# Additional information

(1..1000).each do |page| 
  args = {
    'q' => queryString(q),
    'rows' => ROWS,
    'page' => "#{page*100}",
    'output' => 'json'
  }
  
  stuff = queryURL(HOST,PATH,args)  
  stuff['response']['docs'].each do |doc|
    entry = InternetArchiveEntry.new(doc)
    $data << entry
    print '.'
    puts entry if DEBUG
    puts "===================" if DEBUG
  end
  puts '' if (page%50 == 0)
end
puts 'done'
  
# Store the results of the query
File.open("#{DATA}.yml",'w') do |f|
  f.puts $data.to_yaml
end

InternetArchiveEntry.dump_csv($data, "#{DATA}.csv")
