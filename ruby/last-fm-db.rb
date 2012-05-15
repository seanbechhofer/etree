require 'rubygems'
require "net/http"
require "uri"
require 'getopt/std'
require 'json'
require 'yaml'
require 'csv'
require 'rexml/document'
require 'sqlite3'

LASTFM = "ws.audioscrobbler.com"
LASTFM_KEY = '9e9d232ae6eb9a3ae190bc291f540e71'

def last_fm_query(args) 
  Net::HTTP.start(LASTFM) do |http|
    path = '/2.0/?'
    args.each_key do |k|
      puts "#{k} => #{args[k]}" if BEHAVIOUR[:debug]
      path = path + k + '=' + args[k] + '&'
    end
    path = path + "api_key=#{LASTFM_KEY}"
    
    response = http.get(URI.escape(path))
    result = response.body
    puts result.to_s if BEHAVIOUR[:debug]
    return result
  end
end

def last_fm_venue_query(query, cache_db)
  lastfmResult = ""
  stmt = cache_db.prepare( "select response from lastfm where query=?" )
  rows = stmt.execute(query)
  cached = rows.next() 
  if cached then
    puts "Retrieved from cache" if BEHAVIOUR[:debug]
    puts cached.inspect if BEHAVIOUR[:debug]
    lastfmResult = cached['response']
  else
    puts "Hitting lastfm" if BEHAVIOUR[:debug]
    args = {
      'method' => 'venue.search',
      'venue' => query
    }
    lastfmResult = last_fm_query(args)
    stmt = cache_db.prepare( "insert into lastfm (query,response) values (?,?)" )
    puts "Caching" if BEHAVIOUR[:debug]
    stmt.execute(query, lastfmResult)
  end
  $venues = []
  REXML::XPath.each(REXML::Document.new(lastfmResult), "lfm/results/venuematches/venue") {|v|
    $venue = {
      :id => v.elements["id"].text,
      :name => v.elements["name"].text,
      :city => v.elements["location/city"].text, 
      :country => v.elements["location/country"].text,
      :geo => {
        :lat => v.elements["location/geo:point/geo:lat"].text,
        :lng => v.elements["location/geo:point/geo:long"].text
      },
      :url => v.elements["url"].text
    }
    puts $venue.inspect if BEHAVIOUR[:debug]
    $venues << $venue
  }
  return $venues
end
