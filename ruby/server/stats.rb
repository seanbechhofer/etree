def getStats(endpoint)
# Bit of a hack this. Would be better to directly query the sparql from the page. 
# Returns basic information about numbers of performances per year.

  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo:<http://purl.org/ontology/mo/>

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
  spqresults = endpoint.query( squery )
  years = []
  spqresults.each do |result|
    years << {"year" => result[:year].to_s, "performances" => result[:performances].to_i}
  end
  stuff = {}
  stuff["year.summary"] = years

  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo: <http://purl.org/ontology/mo/>

SELECT (COUNT (?art) AS ?artists) 
WHERE { 
  ?art rdf:type mo:MusicArtist.
}
END
  spqresults = endpoint.query( squery )
  artists = {
    "all" => spqresults[0][:artists].to_s
  }
  
  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo: <http://purl.org/ontology/mo/>
PREFIX sim: <http://purl.org/ontology/similarity/>

SELECT (COUNT (?a) AS ?artists) 
WHERE {
  ?a rdf:type mo:MusicArtist.
  ?sim sim:subject ?a.
  ?sim sim:object ?artMB.
  ?sim sim:method etree:simpleMusicBrainzMatch.
}
END
  spqresults = endpoint.query( squery )
  artists['mb'] = spqresults[0][:artists].to_s
  stuff['artist.summary'] = artists

  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo: <http://purl.org/ontology/mo/>
PREFIX sim: <http://purl.org/ontology/similarity/>

SELECT (COUNT (?a) AS ?artists) 
WHERE {
  ?a rdf:type mo:MusicArtist.
  ?sim sim:subject ?a.
  ?sim sim:object ?artMB.
  ?sim sim:method etree:opMusicBrainzMatch.
}
END
  spqresults = endpoint.query( squery )
  artists['op-mb'] = spqresults[0][:artists].to_s
  stuff['artist.summary'] = artists


  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo: <http://purl.org/ontology/mo/>
PREFIX sim: <http://purl.org/ontology/similarity/>

SELECT (COUNT (?a) AS ?artists) 
WHERE {
  ?a rdf:type mo:MusicArtist.
  ?sim sim:subject ?a.
  ?sim sim:object ?artMB.
  ?sim sim:method etree:opLastFMMatch.
}
END
  spqresults = endpoint.query( squery )
  artists['op-lfm'] = spqresults[0][:artists].to_s
  stuff['artist.summary'] = artists

  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo: <http://purl.org/ontology/mo/>
PREFIX sim: <http://purl.org/ontology/similarity/>

SELECT (COUNT (?p) AS ?performances) 
WHERE {
  ?p rdf:type etree:Concert.
}
END
  spqresults = endpoint.query( squery )
  venues = {
    "all" => spqresults[0][:performances].to_s
  }
  
  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo: <http://purl.org/ontology/mo/>
PREFIX sim: <http://purl.org/ontology/similarity/>
PREFIX event: <http://purl.org/NET/c4dm/event.owl#>
SELECT (COUNT (?venue) AS ?mapped) 
WHERE {
  ?p rdf:type etree:Concert.
  ?p event:place ?venue.
  ?sim sim:subject ?venue.
  ?sim sim:object ?lfm.
  ?sim sim:method etree:simpleLastfmMatch.
} 
END
  spqresults = endpoint.query( squery )
  venues["lastfm"] = spqresults[0][:mapped].to_s

  squery = <<END
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX etree: <http://etree.linkedmusic.org/vocab/>
PREFIX mo: <http://purl.org/ontology/mo/>
PREFIX sim: <http://purl.org/ontology/similarity/>
PREFIX event: <http://purl.org/NET/c4dm/event.owl#>
SELECT (COUNT (?venue) AS ?mapped) 
WHERE {
  ?p rdf:type etree:Concert.
  ?p event:place ?venue.
  {
   {
   ?sim sim:subject ?venue.
   ?sim sim:object ?geo.
   ?sim sim:method etree:simpleGeoAndLastfmMatch.
   } UNION {
   ?sim sim:subject ?venue.
   ?sim sim:object ?geo.
   ?sim sim:method etree:simpleGeoMatch.
   }
  } 
} 
END
  spqresults = endpoint.query( squery )
  venues["geo"] = spqresults[0][:mapped].to_s

  stuff['venue.summary'] = venues
  return stuff
end

def getYearSummary(endpoint, artist)
# Returns basic information about numbers of performances per year.

  clause = ""
  if artist != "" then
    clause = "<#{artist}> mo:performed ?perf."
  end
    
  squery = PREFIXES+<<END
SELECT ?year (COUNT (?perf) AS ?performances) 
WHERE { 
  SELECT DISTINCT ?perf (YEAR(xsd:date(?date)) AS ?year) 
  WHERE { 
    ?perf rdf:type etree:Concert. 
    ?perf etree:date ?date. 
    #{clause}
  } 
} GROUP BY ?year 
ORDER BY ?year
END
  spqresults = endpoint.query( squery )
  years = []
  spqresults.each do |result|
    years << {"year" => result[:year].to_s, "performances" => result[:performances].to_i}
  end
  stuff = {}
  stuff["year.summary"] = years
  return stuff
end

def getYearSummaryCSV(endpoint, artist)
# Returns basic information about numbers of performances per year.

  clause = ""
  if artist != "" then
    clause = "<#{artist}> mo:performed ?perf."
  end
    
  squery = PREFIXES+<<END
SELECT ?year (COUNT (?perf) AS ?performances) 
WHERE { 
  SELECT DISTINCT ?perf (YEAR(xsd:date(?date)) AS ?year) 
  WHERE { 
    ?perf rdf:type etree:Concert. 
    ?perf etree:date ?date. 
    #{clause}
  } 
} GROUP BY ?year 
ORDER BY ?year
END
  spqresults = endpoint.query( squery )
  years = CSV.generate do |csv|
    csv << ["year", "performances"]
    spqresults.each do |result|
      if !result[:year].nil? then
        csv << [result[:year].to_s, result[:performances].to_i]
      end
    end
  end
  return years
end
