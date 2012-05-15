# Query for performances by a particular artist
require 'rubygems'
require 'net/http'
require 'json'
require 'yaml'
require 'csv'
require 'getopt/std'
require 'nokogiri'
require 'open-uri'

RESPONSE = "response.txt"

HOST = 'archive.org'
PATH = '/advancedsearch.php?'
# This won't get everything. Some bands have more than 200 shows 
ROWS = '200'

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

# construct a query URL using the path and args. Returns a hash
def queryURL(host, path, args)
  stuff = {}
  Net::HTTP.start(host) do |http|
    puts escape(path, args) if BEHAVIOUR[:verbose]
    response = http.get(escape(path, args))
    puts response.code if BEHAVIOUR[:verbose]
    puts response["location"] if BEHAVIOUR[:verbose]
    puts response.body if BEHAVIOUR[:verbose]
    File.open(RESPONSE,'w') do |f|
      f.puts response.body
    end
    
    #  puts response
    stuff = JSON.parse(response.body)
    puts "Found: #{stuff['response']['numFound']}" if BEHAVIOUR[:verbose]
  end
  return stuff
end

def getPerformances(artist)
  if (!artist) then
    puts "Need artist!"
    exit
  end
  data = []
  # Query to IA
  q = {
    'mediatype' => 'etree',
    'creator' => artist
  }
  # Additional information about format, number of results etc. 
  args = {
    'q' => queryString(q),
    'rows' => ROWS,
    'page' => "1",
    # We're just going to pull identifiers from here and then use the metadata files
    'fl[]' => 'identifier',
    'output' => 'json'
  }
  begin  
    stuff = queryURL(HOST,PATH,args)  
    stuff['response']['docs'].each do |doc|
      puts doc['identifier'] if BEHAVIOUR[:verbose]
      id = doc['identifier']
      # Grab metadata files using the identifier
      url = "http://www.archive.org/download/#{id}/#{id}_meta.xml"
      event = parseEventMetadataFile(url)
      url = "http://www.archive.org/download/#{id}/#{id}_files.xml"
      files = parseEventFilesFile(url)
      event[:files] = files
      data << event
      puts "===================" if BEHAVIOUR[:debug]
    end
  rescue Exception => e
    puts "Something went wrong #{e}"
  end
  hash = {
    artist => data
  }
  return hash
end

def getPerformanceData(meta, files)
  event = parseEventMetadataFile(meta)
  files = parseEventFilesFile(files)
  event[:files] = files
  return event
end


# Parse an event metadata file 
def parseEventMetadataFile(url)
#  url = "http://www.archive.org/download/#{id}/#{id}_meta.xml"
  puts url if BEHAVIOUR[:verbose]
  event = {}
  doc = Nokogiri::XML(open(url))
  puts doc if BEHAVIOUR[:debug]

  # identifier, title, creator, mediatype, collection, type, description, date, year, publicdate, addeddate, uploader, updater, updatedate, venue, coverage, source, lineage, taper, runtime, notes
  doc.xpath("//metadata").each do |f|
    event[:identifier] = f.xpath("identifier")[0].content if f.xpath("identifier")[0]
    event[:title] = f.xpath("title")[0].content if f.xpath("title")[0]
    event[:creator] = f.xpath("creator")[0].content if f.xpath("creator")[0]
    event[:description] = f.xpath("description")[0].content if f.xpath("description")[0]
    event[:mediatype] = f.xpath("mediatype")[0].content if f.xpath("mediatype")[0]
    event[:date] = f.xpath("date")[0].content if f.xpath("date")[0]
    event[:year] = f.xpath("year")[0].content if f.xpath("year")[0]
    event[:subject] = f.xpath("subject")[0].content if f.xpath("subject")[0]
    event[:venue] = f.xpath("venue")[0].content if f.xpath("venue")[0]
    event[:coverage] = f.xpath("coverage")[0].content if f.xpath("coverage")[0]
    event[:source] = f.xpath("source")[0].content if f.xpath("source")[0]
    event[:lineage] = f.xpath("lineage")[0].content if f.xpath("lineage")[0]
    event[:uploader] = f.xpath("uploader")[0].content if f.xpath("uploader")[0]
    event[:taper] = f.xpath("taper")[0].content if f.xpath("taper")[0]
    event[:transferer] = f.xpath("transferer")[0].content if f.xpath("transferer")[0]
    event[:runtime] = f.xpath("runtime")[0].content if f.xpath("runtime")[0]
    event[:notes] = f.xpath("notes")[0].content if f.xpath("notes")[0]
  end
  puts event if BEHAVIOUR[:debug]
  return event
end

# Parse an event metadata file. 
def parseEventFilesFile(url)
#  url = "http://www.archive.org/download/#{id}/#{id}_files.xml"
  puts url if BEHAVIOUR[:verbose]
  files = []
  doc = Nokogiri::XML(open(url))
  puts doc if BEHAVIOUR[:debug]
  # creator, title, track, album, bitrate, length, format, original, md5, mtime, size, crc32, sha1, album, 
  doc.xpath("//files/file").each do |f|
    file = {}
    file[:name] = f.get_attribute("name") if f.get_attribute("name")
    file[:creator] = f.xpath("creator")[0].content if f.xpath("creator")[0]
    file[:title] = f.xpath("title")[0].content if f.xpath("title")[0]
    file[:album] = f.xpath("album")[0].content if f.xpath("album")[0]
    file[:track] = f.xpath("track")[0].content if f.xpath("track")[0]
    file[:bitrate] = f.xpath("bitrate")[0].content if f.xpath("bitrate")[0]
    file[:length] = f.xpath("length")[0].content if f.xpath("length")[0]
    file[:format] = f.xpath("format")[0].content if f.xpath("format")[0]
    file[:original] = f.xpath("original")[0].content if f.xpath("original")[0]
    file[:md5] = f.xpath("md5")[0].content if f.xpath("md5")[0]
    file[:mtime] = f.xpath("mtime")[0].content if f.xpath("mtime")[0]
    file[:size] = f.xpath("size")[0].content if f.xpath("size")[0]
    file[:crc32] = f.xpath("crc32")[0].content if f.xpath("crc32")[0]
    file[:sha1] = f.xpath("sha1")[0].content if f.xpath("sha1")[0]
    files << file
  end
  puts files if BEHAVIOUR[:debug]
  return files
end

# Just returns the ids for performances for an artists
def getPerformanceIDs(artist)
  if (!artist) then
    puts "Need artist!"
    exit
  end
  ids = []
  # Query to IA
  q = {
    'mediatype' => 'etree',
    'creator' => artist
  }
  # Additional information about format, number of results etc. 
  args = {
    'q' => queryString(q),
    'rows' => ROWS,
    'page' => "1",
    # We're just going to pull identifiers from here and then use the metadata files
    'fl[]' => 'identifier',
    'output' => 'json'
  }
  begin  
    stuff = queryURL(HOST,PATH,args)  
    stuff['response']['docs'].each do |doc|
      puts doc['identifier'] if BEHAVIOUR[:verbose]
      id = doc['identifier']
      ids << id
      puts "===================" if BEHAVIOUR[:debug]
    end
  rescue Exception => e
    puts "Something went wrong #{e}"
  end
  return ids
end
