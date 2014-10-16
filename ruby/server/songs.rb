def getSongCounts(endpoint,artist)
# Bit of a hack this. Would be better to directly query the sparql from the page. 
# Returns basic information about numbers of performances per year.

  squery = <<END
PREFIX etree:<http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>
PREFIX event:<http://purl.org/NET/c4dm/event.owl#>
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX timeline:<http://purl.org/NET/c4dm/timeline.owl#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX sim: <http://purl.org/ontology/similarity/>

SELECT ?trackname ?performances {
  # Q1. Get the tracks from artists and count occurrences, assuming
  # the same name is the same track
  {
    SELECT ?trackname (COUNT(?track) AS ?performances) {
      ?track mo:performer <#{artist}>.
      ?track rdf:type etree:Track.
      ?track skos:prefLabel ?trackname.
    } GROUP BY ?trackname 
  } # End Q1
  # Weed out the chaff
  FILTER (?trackname != "")
  FILTER (?trackname != "tmp")
  FILTER (!regex(?trackname,"tuning","i"))
  FILTER (!regex(?trackname,"intro","i"))
  FILTER (!regex(?trackname,"banter","i"))
  FILTER (!regex(?trackname,"jam","i"))
  FILTER (!regex(?trackname,"encore","i"))
} ORDER BY ?performances

END
  spqresults = endpoint.query( squery )
  counts = []
  spqresults.each do |result|
    counts << {"track" => result[:trackname].to_s, "performances" => result[:performances].to_i}
  end
  stuff = {}
  stuff["track.counts"] = counts

  return stuff
end

