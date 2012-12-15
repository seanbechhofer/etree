#!/opt/local/bin/ruby

require 'rubygems'
require 'getopt/std'
require 'sinatra'
require 'sparql/client'
require 'haml'
require 'markaby'
require 'markaby/sinatra'

BEHAVIOUR = {
  :debug => false,
  :verbose => true
}

#ENDPOINT="http://localhost:3030/etree/sparql"
#ENDPOINT="http://etree.linkedmusic.org/sparql"
ENDPOINT="http://linkedmusic.oerc.ox.ac.uk:3030/etree/sparql"
ETREE="http://etree.linkedmusic.org/"
MBENDPOINT="http://dbtune.org/musicbrainz/sparql"

$sparql = SPARQL::Client.new(ENDPOINT)
$mbsparql = SPARQL::Client.new(MBENDPOINT)

get '/' do
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
  markaby :index, :locals => {:pageTitle => "Home: etree", :tags => results}
end # '/'

def simpleQuery(query, queryType, type) 
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
?thing geo:name ?n.
?thing geo:countryCode ?c.
FILTER regex(?n, "#{query}", "i")
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
  artistID = params[:splat]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT ?event ?eventName WHERE {
<#{artistID}> mo:performed ?event.
?event skos:prefLabel ?eventName.
}
END
  results = $sparql.query( query )
  puts results.inspect if BEHAVIOUR[:verbose]
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?name WHERE {
<#{artistID}> skos:prefLabel ?name.
} 
END
  nameResults = $sparql.query( query )
  artistName = nameResults.first[:name]
  markaby :artist, :locals => {:pageTitle => artistName, :query => artistID, :name => artistName, :results => results}
end
  
get '/track/*' do
  trackID = params[:splat]
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
  perfID = params[:splat]
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

SELECT DISTINCT ?performance ?art ?artist ?date ?uploader ?geo ?location ?country ?lastfm ?lastfmName
{
<#{perfID}> mo:performer ?art;
  etree:uploader ?uploader;
  event:place ?venue;
  event:time ?time;
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
  perfID = params[:splat]
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
        xml<< <<END    
    <track>
      <location>#{result[:audio]}</location>
      <creator>#{result[:artist]}</creator>
      <album>#{result[:performance]}</album>
      <title>#{result[:trackName]}</title>
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
  lastFMID = params[:splat]
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
  markaby :place, :locals => {:pageTitle => venueName, :query => lastFMID, :name => venueName, :results => results}
end

get '/geo/*' do
  geoID = params[:splat]
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
  markaby :place, :locals => {:pageTitle => venueName, :query => geoID, :name => venueName, :results => results}
end

get '/key/*' do
  key = params[:splat]
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
