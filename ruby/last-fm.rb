require 'rubygems'
require "net/http"
require "uri"
require 'getopt/std'
require 'json'
require 'yaml'
require 'csv'
require 'rexml/document'

LASTFM = "ws.audioscrobbler.com"

def last_fm_query(args) 
  Net::HTTP.start(LASTFM) do |http|
    path = '/2.0/?'
    args.each_key do |k|
      puts "#{k} => #{args[k]}" if BEHAVIOUR[:debug]
      path = path + k + '=' + args[k] + '&'
    end
    path = path + "api_key=#{LASTFM_KEY}"
    
    response = http.get(URI.escape(path))
    result = REXML::Document.new(response.body)
    puts result.to_s if BEHAVIOUR[:debug]
    return result
  end
end

def last_fm_venue_query(query)
  args = {
    'method' => 'venue.search',
    'venue' => query
  }
  result = last_fm_query(args)
  $venues = []
  REXML::XPath.each(result, "lfm/results/venuematches/venue") {|v|
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
