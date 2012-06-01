# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'sparql/client'
require 'haml'
require 'markaby'
require 'markaby/sinatra'

ENDPOINT="http://etree.linkedmusic.org/sparql"
ETREE="http://etree.linkedmusic.org/"

set :markaby, {:indent => 2}

sparql = SPARQL::Client.new(ENDPOINT)

get '/' do
  markaby :index
end

get '/search' do
  type = params[:type]
  query = params[:query]
  puts "#{type}, #{query}" 
  if type.eql?("artist") then
    queryType = "?thing rdf:type mo:MusicArtist."
  elsif type.eql?("event") then
    queryType = "?thing rdf:type etree:Concert."
  else
    markaby :unknown
  end
  squery = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
SELECT ?thing ?label WHERE {
#{queryType}
?thing skos:prefLabel ?label.
FILTER regex(?label, "#{query}", "i")
} ORDER BY ?label
END
  results = sparql.query( squery )
  puts results.inspect
  markaby :search, :locals => {:query => query, :type => type, :results => results}
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
  results = sparql.query( query )
  puts results.inspect
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?name WHERE {
<#{artistID}> skos:prefLabel ?name.
} 
END
  nameResults = sparql.query( query )
  artistName = nameResults.first[:name]
  markaby :artist, :locals => {:query => artistID, :name => artistName, :results => results}
end
  
get '/event/*' do
  puts params.inspect
  perfID = params[:splat]
  puts perfID
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
  results = sparql.query( query )
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
  trackResults = sparql.query( trackQuery )
  puts trackResults.inspect
  markaby :event, :locals => {:id => perfID, :results => results, :tracks => trackResults}
end

get '/playlist/*' do
  puts params.inspect
  perfID = params[:splat]
  puts perfID
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
  puts query
  results = sparql.query( query )
  puts results.inspect
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
  puts query
  results = sparql.query( query )
  puts results.inspect
  query = <<END
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?name WHERE {
<#{lastFMID}> skos:prefLabel ?name.
} 
END
  nameResults = sparql.query( query )
  venueName = nameResults.first[:name]
  markaby :place, :locals => {:query => lastFMID, :name => venueName, :results => results}
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
  puts query
  results = sparql.query( query )
  puts results.inspect
  query = <<END
PREFIX geo:<http://www.geonames.org/ontology#>

SELECT DISTINCT ?name WHERE {
<#{geoID}> geo:name ?name.
} 
END
  nameResults = sparql.query( query )
  venueName = nameResults.first[:name]
  markaby :place, :locals => {:query => geoID, :name => venueName, :results => results}
end
