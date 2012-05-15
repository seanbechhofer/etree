require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'date'
require 'getopt/std'
require 'csv'
require 'geokit'
require 'sqlite3'

GEONAMES='api.geonames.org'

THRESHOLD = 0.8
DISTANCE_THRESHOLD = 10


def query(args) 
  path = '/search?'
  args.each_key do |k|
    path = path + k + '=' + args[k] + '&'
  end
  path = path + 'username=sean.bechhofer'
  return URI.escape(path)
end

def geoQuery(query,cache_db)
  results = []
  geoResult = ""
  stmt = cache_db.prepare( "select response from geonames where query=?" )
  rows = stmt.execute(query)
  cached = rows.next() 
  if cached then
    puts "Retrieved from cache" if BEHAVIOUR[:debug]
    puts cached.inspect if BEHAVIOUR[:debug]
    geoResult = cached['response']
  else
    puts "Hitting geonames" if BEHAVIOUR[:debug]
    Net::HTTP.start(GEONAMES) do |http|
      args = {
        'q' => query,
        'featureClass' => 'P'
      }
      puts http.inspect if BEHAVIOUR[:debug]
      geoResult = http.get(query(args)).body
      stmt = cache_db.prepare( "insert into geonames (query,response) values (?,?)" )
      puts "Caching" if BEHAVIOUR[:debug]
      stmt.execute(query, geoResult)
    end
  end
  info = REXML::Document.new(geoResult)
  puts info.to_s if BEHAVIOUR[:debug]
  REXML::XPath.each(info, "geonames/geoname") {|geoname|
    results << {
      :name => geoname.elements["name"].text,
      :id => geoname.elements["geonameId"].text,
      :country => geoname.elements["countryCode"].text,
      :lat => geoname.elements["lat"].text,
      :lng => geoname.elements["lng"].text,
      :fcode => geoname.elements["fcode"].text
    }
  }
  return results
end

# Takes two hashes with :lat, :lng entries that represent lat longs. 
def distance(place1, place2) 
  gkl1 = Geokit::LatLng.new(place1[:lat],place1[:lng])
  gkl2 = Geokit::LatLng.new(place2[:lat],place2[:lng])
  return gkl1.distance_to(gkl2)
end

def rank(candidate) 
  # Just rank on lexical distance
  if candidate[:jaro] then
    return candidate[:jaro] 
  else
    return 100
  end
  #return DISTANCE_THRESHOLD - candidate[:distance]
end

def topCandidates(candidates, n)
  return (candidates.sort_by {|candidate| rank(candidate)}).reverse[0..(n-1)]
end

def findCandidates(place, location, cache_db)
  candidates = []
  puts place if BEHAVIOUR[:debug]
  # Query last.fm
  venues = last_fm_venue_query(place, cache_db)
  puts "#{venues.size} venues" if BEHAVIOUR[:debug]

  # Query geonames
  geoLocs = geoQuery(location,cache_db)
  puts "#{geoLocs.size} locations" if BEHAVIOUR[:debug]

  venues.each do |venue|
    geoLocs.each do |glocation|
      puts "#{venue[:name]} x #{glocation[:name]}" if BEHAVIOUR[:debug]
      # Check they're geographically close
      distance = distance(glocation, venue[:geo])
      if distance < DISTANCE_THRESHOLD then
        matcher = Jaro.new(location)
        jaro_match = matcher.match(glocation[:name])
        if jaro_match > THRESHOLD
          candidates << {
            :place => place,
            :location => location,
            :lastfm => venue,
            :geonames => glocation,
            :jaro => jaro_match,
            :distance => distance
          }
        end
      end
    end
  end

  # If we haven't found any candidates, just go on the first geonames hit.

  if candidates.size == 0 then 
    if geoLocs.size > 0 then
      candidates << {
        :place => place,
        :location => location,
        :geonames => geoLocs[0]
      }
    end
  end
  return candidates
end
