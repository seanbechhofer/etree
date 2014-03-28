require 'rubygems'
require 'sqlite3'
require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'getopt/std'
require 'config'

# Specify Database file
DATABASE.results_as_hash = true
LOCATIONS = DATABASE
# LOCATIONS = SQLite3::Database.new( "db/locations.db" )
# LOCATIONS.results_as_hash = true

# Initialise the database tables
def initialise()
  DATABASE.execute( "create table artists (id TEXT KEY, name TEXT KEY, mbId TEXT);" )
  DATABASE.execute( "create table meta (identifier TEXT KEY,\
title TEXT,\
creator TEXT,\
description TEXT,\
mediatype TEXT,\
date TEXT,\
year TEXT,\
subject TEXT,\
venue TEXT,\
coverage TEXT,\
source TEXT,\
lineage TEXT,\
uploader TEXT,\
taper TEXT,\
transferer TEXT,\
runtime TEXT,\
notes TEXT); ")
  DATABASE.execute( "create table files (name TEXT KEY,\
creator TEXT,\
title TEXT,\
album TEXT,\
track TEXT,\
bitrate TEXT,\
length TEXT,\
format TEXT,\
original TEXT,\
md5 TEXT,\
mtime TEXT,\
size TEXT,\
crc32 TEXT,\
sha1 TEXT,\
event TEXT);" )
end

# Add artists
def addArtists(table)
  artists = YAML.load_file(table)
  artists.each do |k,v|
    puts k + ":" + artists[k][:id] if BEHAVIOUR[:verbose]
    ins = DATABASE.prepare( "insert into artists (name,id) values (?,?);" )
    ins.execute(k, artists[k][:id])
    if artists[k][:mb_id] then
      ins = DATABASE.prepare( "update artists set mbId=? where name=?;" ) 
      ins.execute(artists[k][:mb_id], k)
    end
  end
end

def db_getArtistId(name) 
  stmt = DATABASE.prepare( "select id from artist where name=?;")
  row = stmt.execute(name).next
  if row then
    return row[0]
  end
  return nil
end

def db_getArtistMBId(name) 
  stmt = DATABASE.prepare( "select mbId from artist where name=?;")
  row = stmt.execute(name).next
  if row then
    return row[0]
  end
  return nil
end
def db_addArtist(name) 
  uuid = UUID.new
  newId = UUID.generate
  ins = DATABASE.prepare( "insert into artist (name,id) values (?,?);" )
  ins.execute(name,newId)
end

# Check to see if this key is there. If not, generate a new entry with an id. 
def db_checkForArtist(artistName) 
  id = db_getArtistId(artistName)
  if !id then
    db_addArtist(artistName)
  end
end

# Parse an event metadata file 
def addEventMetadataFile(url)
#  url = "http://www.archive.org/download/#{id}/#{id}_meta.xml"
  puts url if BEHAVIOUR[:verbose]
  event = {}
  doc = Nokogiri::XML(open(url))
  puts doc if BEHAVIOUR[:debug]
  
  # identifier, title, creator, mediatype, collection, type, description, date, year, publicdate, addeddate, uploader, updater, updatedate, venue, coverage, source, lineage, taper, runtime, notes
  doc.xpath("//metadata").each do |f|
    event[:identifier] = ""
    event[:identifier] = f.xpath("identifier")[0].content if f.xpath("identifier")[0]
    event[:title] = ""
    event[:title] = f.xpath("title")[0].content if f.xpath("title")[0]
    event[:creator] = ""
    event[:creator] = f.xpath("creator")[0].content if f.xpath("creator")[0]
    event[:description] = ""
    event[:description] = f.xpath("description")[0].content if f.xpath("description")[0]
    event[:mediatype] = ""
    event[:mediatype] = f.xpath("mediatype")[0].content if f.xpath("mediatype")[0]
    event[:date] = ""
    event[:date] = f.xpath("date")[0].content if f.xpath("date")[0]
    event[:year] = ""
    event[:year] = f.xpath("year")[0].content if f.xpath("year")[0]
    event[:subject] = ""
    event[:subject] = f.xpath("subject")[0].content if f.xpath("subject")[0]
    event[:venue] = ""
    event[:venue] = f.xpath("venue")[0].content if f.xpath("venue")[0]
    event[:coverage] = ""
    event[:coverage] = f.xpath("coverage")[0].content if f.xpath("coverage")[0]
    event[:source] = ""
    event[:source] = f.xpath("source")[0].content if f.xpath("source")[0]
    event[:lineage] = ""
    event[:lineage] = f.xpath("lineage")[0].content if f.xpath("lineage")[0]
    event[:uploader] = ""
    event[:uploader] = f.xpath("uploader")[0].content if f.xpath("uploader")[0]
    event[:taper] = ""
    event[:taper] = f.xpath("taper")[0].content if f.xpath("taper")[0]
    event[:transferer] = ""
    event[:transferer] = f.xpath("transferer")[0].content if f.xpath("transferer")[0]
    event[:runtime] = ""
    event[:runtime] = f.xpath("runtime")[0].content if f.xpath("runtime")[0]
    event[:notes] = ""
    event[:notes] = f.xpath("notes")[0].content if f.xpath("notes")[0]
    ins = DATABASE.prepare( "insert into meta (identifier,title,creator,description,mediatype,date,year,subject,venue,coverage,source,lineage,uploader,taper,transferer,runtime,notes) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);" )
    ins.execute(event[:identifier],event[:title],event[:creator],event[:description],event[:mediatype],event[:date],event[:year],event[:subject],event[:venue],event[:coverage],event[:source],event[:lineage],event[:uploader],event[:taper],event[:transferer],event[:runtime],event[:notes])
  end
  return event
end

# Parse an event metadata file. 
def addEventFilesFile(url,event)
  puts url if BEHAVIOUR[:verbose]
  files = []
  doc = Nokogiri::XML(open(url))
  puts doc if BEHAVIOUR[:debug]
  # creator, title, track, album, bitrate, length, format, original, md5, mtime, size, crc32, sha1, album, 
  doc.xpath("//files/file").each do |f|
    file = {}
    file[:name] = ""
    file[:name] = f.get_attribute("name") if f.get_attribute("name")
    file[:creator] = ""
    file[:creator] = f.xpath("creator")[0].content if f.xpath("creator")[0]
    file[:title] = ""
    file[:title] = f.xpath("title")[0].content if f.xpath("title")[0]
    file[:album] = ""
    file[:album] = f.xpath("album")[0].content if f.xpath("album")[0]
    file[:track] = ""
    file[:track] = f.xpath("track")[0].content if f.xpath("track")[0]
    file[:bitrate] = ""
    file[:bitrate] = f.xpath("bitrate")[0].content if f.xpath("bitrate")[0]
    file[:length] = ""
    file[:length] = f.xpath("length")[0].content if f.xpath("length")[0]
    file[:format] = ""
    file[:format] = f.xpath("format")[0].content if f.xpath("format")[0]
    file[:original] = ""
    file[:original] = f.xpath("original")[0].content if f.xpath("original")[0]
    file[:md5] = ""
    file[:md5] = f.xpath("md5")[0].content if f.xpath("md5")[0]
    file[:mtime] = ""
    file[:mtime] = f.xpath("mtime")[0].content if f.xpath("mtime")[0]
    file[:size] = ""
    file[:size] = f.xpath("size")[0].content if f.xpath("size")[0]
    file[:crc32] = ""
    file[:crc32] = f.xpath("crc32")[0].content if f.xpath("crc32")[0]
    file[:sha1] = ""
    file[:sha1] = f.xpath("sha1")[0].content if f.xpath("sha1")[0]
    ins = DATABASE.prepare( "insert into files (name,creator,title,album,track,bitrate,length,format,original,md5,mtime,size,crc32,sha1,event) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);" )
    ins.execute(file[:name],file[:creator],file[:title],file[:album],file[:track],file[:bitrate],file[:length],file[:format],file[:original],file[:md5],file[:mtime],file[:size],file[:crc32],file[:sha1],event)
  end
  return files
end

