#!/opt/local/bin/ruby

require 'rubygems'
require 'getopt/std'
require 'sinatra'
require 'sparql/client'
#require 'haml'
require 'markaby'
require 'markaby/sinatra'
require 'json'

set :port, 31415
# Listen to any host
set :bind, '0.0.0.0'
# Dealing with //
set :protection, :except => :path_traversal

BEHAVIOUR = {
  :debug => false,
  :verbose => true
}

#ENDPOINT="http://localhost:3030/etree/sparql"
ENDPOINT="http://etree.linkedmusic.org/sparql"
#ENDPOINT="http://linkedmusic.oerc.ox.ac.uk:3030/etree/sparql"
ETREE="http://etree.linkedmusic.org/"
MBENDPOINT="http://dbtune.org/musicbrainz/sparql"

QUERYCACHE = {}
TAGSCACHE = nil
ARTISTSCACHE = nil
LOCATIONSCACHE = nil
VENUESCACHE = nil

$sparql = SPARQL::Client.new(ENDPOINT)
$mbsparql = SPARQL::Client.new(MBENDPOINT)

get '/' do
  results = TAGSCACHE
  if results == nil then
    squery = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?tag WHERE
{
?art rdf:type mo:MusicArtist.
?art mo:performed ?perf.
?art skos:prefLabel ?artist.
?art etree:mbTag ?tag.
} ORDER BY ?tag
END
    
    spqresults = $sparql.query( squery )
    results = []
    spqresults.each do |result|
      results << {:tn => result[:tag]}
    end
    TAGSCACHE = results
  end
  markaby :index, :locals => {:pageTitle => "Home: etree", :tags => results}
end # '/'

def URIEncode(uri)
  return URI.encode(uri.to_s(),"/")
end

def simpleQuery(query, queryType, type) 
  results = nil
  hash = query+queryType+type
  if QUERYCACHE.has_key?(hash) then
    puts "Retrieving from cache"
    results = QUERYCACHE[hash]
  else
    squery = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
SELECT ?thing ?label WHERE {
#{queryType}
FILTER regex(?label, "#{query}", "i")
} ORDER BY ?label
END
    puts squery if BEHAVIOUR[:verbose]
    results = $sparql.query( squery )
    QUERYCACHE[hash] = results
  end
  puts results.inspect if BEHAVIOUR[:verbose]
  markaby :search, :locals => {:pageTitle => "Search: #{query}", :query => query, :type => type, :results => results}
end

def locationQuery(query, queryType, type) 
  squery = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
SELECT ?thing (concat(?n, ", ", ?c) as ?label) WHERE {
{
?thing geo:name ?n.
?thing geo:countryCode ?c.
FILTER regex(?n, "#{query}", "i")
} 
UNION
{
?thing geo:name ?n.
?thing geo:countryCode ?c.
FILTER regex(?c, "#{query}", "i")
}
} ORDER BY ?label

END
  puts squery if BEHAVIOUR[:verbose]
  results = $sparql.query( squery )
  puts results.inspect if BEHAVIOUR[:verbose]
  markaby :search, :locals => {:pageTitle => "Search: #{query}", :query => query, :type => type, :results => results}
end

def genreQuery(genre)
  squery = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?thing ?label WHERE
{
?thing rdf:type mo:MusicArtist.
?thing skos:prefLabel ?label.
?thing etree:mbTag "#{genre}".
}
END
  puts squery if BEHAVIOUR[:verbose]
  results = $sparql.query( squery )
  puts results.inspect if BEHAVIOUR[:verbose]
  markaby :search, :locals => {:pageTitle => "Search: #{genre}", :query => genre, :type => "artist", :results => results}
end

def trackQuery(query)
  squery = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?track ?label ?artist ?eventName ?num WHERE
{
?track rdf:type etree:Track.
?track skos:prefLabel ?label.
?track etree:isSubEventOf ?event.
?event skos:prefLabel ?eventName.
?track etree:number ?num.
FILTER regex(?label, "#{query}", "i")
?track mo:performer ?art.
?art skos:prefLabel ?artist.
}
END
  puts squery if BEHAVIOUR[:verbose]
  results = $sparql.query( squery )
  puts results.inspect if BEHAVIOUR[:verbose]
  markaby :tracksearch, :locals => {:pageTitle => "Tracks: #{query}", :query => query, :results => results}
end

get '/search' do
  type = params[:type]
  query = params[:query]
  puts "#{type}, #{query}" if BEHAVIOUR[:verbose]
  if type.eql?("artist") then
    queryType = "?thing rdf:type mo:MusicArtist. ?thing skos:prefLabel ?label."
    simpleQuery(query, queryType, type)
  elsif type.eql?("event") then
    queryType = "?thing rdf:type etree:Concert. ?thing skos:prefLabel ?label."
    simpleQuery(query, queryType, type)
  elsif type.eql?("geo") then
    locationQuery(query, queryType, type)
#    queryType = "?thing geo:name ?label."
#    simpleQuery(query, queryType, type)
  elsif type.eql?("track") then
    trackQuery(query)
#    queryType = "?thing rdf:type etree:Track. ?thing skos:prefLabel ?label."
#    simpleQuery(query, queryType, type)
  elsif type.eql?("genre") then
    genreQuery(params[:genre])
  else
    markaby :unknown, :locals => {:pageTitle => "Unknown!"}
  end
end
  
get '/artist/*' do
  artistID = params[:splat][0]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>

SELECT ?event ?eventName ?date WHERE {
<#{artistID}> mo:performed ?event.
?event skos:prefLabel ?eventName.
?event event:time ?time.
?time timeline:beginsAtDateTime ?date.

} ORDER BY DESC(?date)
END
  results = $sparql.query( query )
  puts results.inspect if BEHAVIOUR[:verbose]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>

SELECT DISTINCT ?name ?artMB WHERE {
<#{artistID}> skos:prefLabel ?name.
OPTIONAL {
?sim sim:subject <#{artistID}>.
?sim sim:object ?artMB.
?sim sim:method etree:simpleMusicBrainzMatch.
}
} 
END
  nameResults = $sparql.query( query )
  artistName = nameResults.first[:name]
  artistMB = nameResults.first[:artMB]
  markaby :artist, :locals => {:pageTitle => artistName, :query => artistID, :name => artistName, :mb => artistMB, :results => results}
end
  
get '/track/*' do
  trackID = params[:splat][0]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
SELECT ?artist ?trackName ?artistName ?event ?eventName ?num WHERE {
<#{trackID}> mo:performer ?artist.
?artist skos:prefLabel ?artistName.
<#{trackID}> skos:prefLabel ?trackName.
<#{trackID}> etree:isSubEventOf ?event.
<#{trackID}> etree:number ?num.
?event skos:prefLabel ?eventName.
}
END
  results = $sparql.query( query )
  markaby :track, :locals => {:pageTitle => "Track", :query => trackID, :results => results}
end

get '/event/*' do
  puts params.inspect if BEHAVIOUR[:verbose]
  perfID = params[:splat][0]
  puts perfID if BEHAVIOUR[:verbose]
  query = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?performance ?id ?art ?artist ?artMB ?date ?description ?uploader ?geo ?location ?country ?lastfm ?lastfmName
{
<#{perfID}> mo:performer ?art;
  etree:uploader ?uploader;
  etree:id ?id;
  event:place ?venue;
  event:time ?time;
  etree:description ?description;
  skos:prefLabel ?performance.

?art skos:prefLabel ?artist.

?time timeline:beginsAtDateTime ?date.

OPTIONAL {
?sim sim:subject ?venue.
?sim sim:object ?geo.
?geo geo:name ?location.
?geo geo:countryCode ?country.
}

OPTIONAL {
?sim2 sim:subject ?venue.
?sim2 sim:object ?lastfm.
?sim2 sim:method etree:simpleLastfmMatch.
?lastfm skos:prefLabel ?lastfmName.
}

OPTIONAL {
?sim3 sim:subject ?art.
?sim3 sim:object ?artMB.
?sim3 sim:method etree:simpleMusicBrainzMatch.
}

}
END
  results = $sparql.query( query )
  trackQuery = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?track ?trackName ?trackNumber  
{
<#{perfID}> event:hasSubEvent ?track.
?track skos:prefLabel ?trackName.
?track etree:number ?trackNumber.
} ORDER BY ?trackNumber
END
  trackResults = $sparql.query( trackQuery )
  puts trackResults.inspect if BEHAVIOUR[:verbose]
  keyQuery = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?keyword
{
<#{perfID}> etree:keyword ?keyword.
}
END
  keyResults = $sparql.query( keyQuery )
  puts keyResults.inspect if BEHAVIOUR[:verbose]
  markaby :event, :locals => {:pageTitle => perfID, :id => perfID, :results => results, :tracks => trackResults, :keys => keyResults}
end

get '/playlist/*' do
  puts params.inspect if BEHAVIOUR[:verbose]
  perfID = params[:splat][0]
  # Horrible hack. Some issue with ruby/sinatra losing //
  if !perfID.match("http://") then
    perfID = perfID.sub!("http:/","http://")
  end
  # end Horribla hack
  puts perfID if BEHAVIOUR[:verbose]
  query = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?performance ?track ?trackName ?trackNumber ?audio {
<#{perfID}> event:hasSubEvent ?track;
 mo:performer ?art;
 skos:prefLabel ?performance.

?art skos:prefLabel ?artist.

?track skos:prefLabel ?trackName.
?track etree:number ?trackNumber.
?track etree:audio ?audio.
} ORDER BY ?trackNumber
END
  xml = <<END
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>Playlist</title>
  <trackList>
END
  puts query if BEHAVIOUR[:verbose]
  results = $sparql.query( query )
  puts results.inspect if BEHAVIOUR[:verbose]
  done = []
  results.each do |result|
    if (result[:audio].to_s.end_with?("mp3")) then
      if !done.include?(result[:trackNumber].to_i) then
        trackName = result[:trackName].to_s
        if trackName.empty? then
          trackName = "??"
        end
        xml<< <<END    
    <track>
      <location>#{result[:audio]}</location>
      <creator>#{result[:artist]}</creator>
      <album>#{result[:performance]}</album>
      <title>#{trackName}</title>
      <image>/music.png</image>
    </track>
END
        done << result[:trackNumber].to_i
      end
    end
  end
  xml<< <<END
  </trackList>
</playlist>
END
  headers 'Content-Type' => 'application/xml' 
  content_type "application/xml"
  xml
end

get '/lastfm/*' do
  lastFMID = params[:splat][0]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>

SELECT DISTINCT ?evt ?event ?sim WHERE {
?evt event:place ?place.
?evt skos:prefLabel ?event.
?sim sim:subject ?place.
?sim sim:method etree:simpleLastfmMatch.
?sim sim:object <#{lastFMID}>.
} ORDER BY ?event
END
  puts query if BEHAVIOUR[:verbose]
  results = $sparql.query( query )
  puts results.inspect if BEHAVIOUR[:verbose]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?name WHERE {
<#{lastFMID}> skos:prefLabel ?name.
} 
END
  nameResults = $sparql.query( query )
  venueName = nameResults.first[:name]
  markaby :lastfm, :locals => {:pageTitle => venueName, :query => lastFMID, :name => venueName, :results => results}
end

get '/geo/*' do
  geoID = params[:splat][0]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>

SELECT DISTINCT ?evt ?event ?sim WHERE {
?evt event:place ?place.
?evt skos:prefLabel ?event.
?sim sim:subject ?place.
{
 {?sim sim:method etree:simpleGeoMatch.}
  UNION
 {?sim sim:method etree:simpleGeoAndLastfmMatch.}
}
?sim sim:object <#{geoID}>.
} ORDER BY ?event
END
  puts query if BEHAVIOUR[:verbose]
  results = $sparql.query( query )
  puts results.inspect if BEHAVIOUR[:verbose]
  query = <<END
PREFIX geo:<http://www.geonames.org/ontology#>

SELECT DISTINCT ?name WHERE {
<#{geoID}> geo:name ?name.
} 
END
  nameResults = $sparql.query( query )
  venueName = nameResults.first[:name]
  markaby :geo, :locals => {:pageTitle => venueName, :query => geoID, :name => venueName, :results => results}
end

get '/key/*' do
  key = params[:splat][0]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>

SELECT DISTINCT ?thing ?label WHERE {
?thing etree:keyword "#{key}".
?thing skos:prefLabel ?label.
}
END
  puts query if BEHAVIOUR[:verbose]
  results = $sparql.query( query )
  markaby :search, :locals => {:pageTitle => key, :query => key, :type => "event", :results => results}
end

get '/artists' do
  results = ARTISTSCACHE
  if results == nil then
    squery = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
SELECT ?thing ?label WHERE {
?thing rdf:type mo:MusicArtist.
?thing skos:prefLabel ?label.
} ORDER BY ?label
END
    puts squery if BEHAVIOUR[:verbose]
    results = $sparql.query( squery )
    ARTISTSCACHE = results
  end
  puts results.inspect if BEHAVIOUR[:verbose]
  markaby :things, :locals => {:pageTitle => "Artists", :type => "artist", :typeLabel => "Artists", :results => results}
end

get '/locations' do
  results = LOCATIONSCACHE
  if results == nil then
    squery = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
SELECT DISTINCT ?thing (concat(?n, ", ", ?c) as ?label) WHERE {
?thing geo:name ?n.
?thing geo:countryCode ?c.
} ORDER BY ?label
END
    puts squery if BEHAVIOUR[:verbose]
    results = $sparql.query( squery )
    LOCATIONSCACHE = results
  end
  puts results.inspect if BEHAVIOUR[:verbose]
  markaby :things, :locals => {:pageTitle => "Locations", :type => "geo", :typeLabel => "Locations", :results => results}
end

get '/venues' do
  results = VENUESCACHE
  if results == nil then
    squery = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX geo:<http://www.geonames.org/ontology#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX sim:<http://purl.org/ontology/similarity/>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
SELECT DISTINCT ?thing ?label WHERE {
?sim sim:object ?thing.
?sim sim:method etree:simpleLastfmMatch.
?thing skos:prefLabel ?label.
} ORDER BY ?label
END
    puts squery if BEHAVIOUR[:verbose]
    results = $sparql.query( squery )
    VENUESCACHE = results
  end
  puts results.inspect if BEHAVIOUR[:verbose]
  markaby :things, :locals => {:pageTitle => "Venues", :type => "lastfm", :typeLabel => "Last FM Venues", :results => results}
end

get '/year-summary' do
# Bit of a hack this. Would be better to directly query the sparql from the page. 
# Returns basic information about numbers of performances per year.
  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
SELECT ?year (COUNT (?perf) AS ?performances) 
WHERE { 
  SELECT DISTINCT ?perf (YEAR(xsd:date(?date)) AS ?year) 
  WHERE { 
    ?perf rdf:type etree:Concert. 
    ?perf etree:date ?date. 
  } 
} GROUP BY ?year 
ORDER BY ?year
END
  spqresults = $sparql.query( squery )
  stuff = []
  spqresults.each do |result|
    stuff << {"year" => result[:year].to_s, "performances" => result[:performances].to_i}
  end
  stuff.to_json
end

