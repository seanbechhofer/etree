# Tries to match venues with geonames and lastfm. 

# Separate tables!!! Doh!

require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'date'
require 'getopt/std'
require 'csv'
require 'amatch'
include Amatch
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'keys'
require 'geo-db'
require 'last-fm-db'
require 'sqlite3'
require 'db'

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

# Find suitable mappings for the pair of name/location. If found, add them to the database.
def mash(name,location)
  begin
    candidates = findCandidates(name, location, database) 
    puts "Found #{candidates.size}" if BEHAVIOUR[:verbose]
    candidate = topCandidates(candidates, 1)[0]
    if candidate then
      if candidate[:lastfm] then
        puts "#{candidate[:lastfm][:id]},#{candidate[:lastfm][:name]}" if BEHAVIOUR[:verbose]
        puts "#{candidate[:geonames][:id]},#{candidate[:geonames][:name]},#{candidate[:geonames][:fcode]},#{candidate[:geonames][:country]}" if BEHAVIOUR[:verbose ]
        puts "#{candidate[:jaro]}" if BEHAVIOUR[:verbose]
        puts "#{candidate[:distance]}" if BEHAVIOUR[:verbose]
        puts "=====" if BEHAVIOUR[:verbose]
        stmt = LOCATIONS.prepare( "insert into locations (name,location,lastfm_id,lastfm_name,geo_id,geo_name,geo_fcode,geo_country,jaro,distance) values (?,?, ?,?,?,?,?,?,?,?)" )
        stmt.execute(name,location,
                     candidate[:lastfm][:id], candidate[:lastfm][:name],
                     candidate[:geonames][:id], candidate[:geonames][:name],
                     candidate[:geonames][:fcode], candidate[:geonames][:country],
                     candidate[:jaro],candidate[:distance])
        puts "Inserted" if BEHAVIOUR[:debug]
      else 
        puts "#{candidate[:geonames][:id]},#{candidate[:geonames][:name]},#{candidate[:geonames][:fcode]},#{candidate[:geonames][:country]}" if BEHAVIOUR[:verbose]
        puts "=====" if BEHAVIOUR[:verbose]
        stmt = LOCATIONS.prepare( "insert into locations (name,location,geo_id,geo_name,geo_fcode,geo_country,jaro,distance) values (?,?,?,?,?,?,?,?)" )
        stmt.execute(name,location,candidate[:geonames][:id], candidate[:geonames][:name],
                     candidate[:geonames][:fcode],candidate[:geonames][:country])
        
      end
    else
      # No candidate. Stick blanks into db. 
      stmt = LOCATIONS.prepare( "insert into locations (name,location,lastfm_id,geo_id) values (?,?,?,?)" )
      stmt.execute(name,location,"-----","-----")
    end
  rescue Exception => ex
    puts "Problem: #{ex.inspect}"
  end
end

opt = Getopt::Std.getopts("l:p:f:o:y:vd")

if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end

count = 0
chunk =  100
offset = 0
finished = false
until finished 
  puts "@@@ Chunk #{offset}"
  # Assume we're done
  finished = true
  #  rows = LOCATIONS.execute( "select venue, name, location from venues;" )
  stmt = LOCATIONS.prepare( "select venue, name, location from venues limit ? offset ?;" )
  rows = stmt.execute(chunk, offset*chunk);
  #  rows = LOCATIONS.execute( "select venue, name, location from venues where (name LIKE 'M%' or name LIKE 'N%' or name LIKE 'O%' or name LIKE 'P%' or name LIKE 'Q%' or name LIKE 'R%' or name LIKE 'S%');" )
  #  rows = LOCATIONS.execute( "select venue, name, location from venues where (name LIKE 'T%' or name LIKE 'U%' or name LIKE 'V%' or name LIKE 'W%' or name LIKE 'X%' or name LIKE 'Y%' or name LIKE 'Z%');" )
  rows.each do |row| 
    # There was a row, so we're not done yet.
    finished = false
    count = count + 1 
    puts "#{count}: #{row['name']}, #{row['location']}"
    stmt = LOCATIONS.prepare( "select name, location from locations where name=? and location=?" )
    existing = stmt.execute(row['name'],row['location']).next()
    if existing then
      #        puts "Already done!"
    else
      mash(row['name'],row['location'])
    end
  end
  offset = offset + 1
end

  
