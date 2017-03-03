require 'rubygems'
require 'net/http'
require 'json'
require 'yaml'
require 'csv'
require 'rbrainz'
require 'getopt/std'
require 'rdf'
require 'rdf/ntriples'
require 'config'
require 'uuid'
require 'sqlite3'

def generateLastFMMappingRDF()
  $graph = RDF::Graph.new

  stmt = DATABASE.prepare( 'select identifier, venue, coverage from meta' )
  rows = stmt.execute()
  type = RDF.type

  rows.each do |row|
    puts row['identifier'] if BEHAVIOUR[:debug]
    puts row['venue'] if BEHAVIOUR[:debug]
    puts row['coverage'] if BEHAVIOUR[:debug]
    
    stmt = LOCATIONS.prepare( 'select lastfm_id from locations where name=? and location=?' )
    lfms = stmt.execute(row['venue'],row['coverage'])
    lfms.each do |lfm|
      if (lfm['lastfm_id'] && !lfm['lastfm_id'].eql?("")) then
        venue = RDF::URI.new(ONTOLOGY + "venue/" + row['identifier'])
        lastfm = RDF::URI.new("http://www.last.fm/venue/" + lfm['lastfm_id'])
        # Give the node an id so that pubby handles it well. @@Hack.
        sim = RDF::URI.new(ONTOLOGY + "venue/" + row['identifier'] + "/lastfm-sim" )
        $graph << [sim, type, VOCAB_SIM_SIMILARITY]
        $graph << [sim, VOCAB_SIM_SUBJECT, venue]
        $graph << [venue, VOCAB_SIM_SUBJECT_OF, sim]
        $graph << [sim, VOCAB_SIM_OBJECT, lastfm]
        $graph << [lastfm, VOCAB_SIM_OBJECT_OF, sim]
        $graph << [sim, VOCAB_SIM_METHOD, VOCAB_ETREE_SIMPLE_LASTFM_MATCH]

        # Provenance triple -- this conversion was made by an activity that Sean was responsible for. 
        $graph << [sim, VOCAB_PROV_ATTRIBUTED_TO, SEAN]
      end
    end
  end
  return $graph
end

# Should probably chunk this into multiple queries.

def generateGeoNamesMappingRDF()
  $graph = RDF::Graph.new

  count = 0
  chunk =  200
  offset = 0
  finished = false
  until finished
    puts "@@@ Chunk #{offset}" if BEHAVIOUR[:verbose]
    # Assume we're done
    finished = true

    stmt = DATABASE.prepare( 'select meta.identifier, locations.name, locations.location, locations.geo_id, locations.lastfm_id from meta, locations where meta.venue=locations.name and meta.coverage=locations.location limit? offset ?' );
    rows = stmt.execute(chunk, offset*chunk)
    puts "@@@ Queried" if BEHAVIOUR[:verbose]
    
    type = RDF.type
    rows.each do |row|
      finished = false
      puts row['identifier'] if BEHAVIOUR[:debug]
      puts row['geo_id'] if BEHAVIOUR[:debug]
      if row['geo_id'] != "-----" then
        venue = RDF::URI.new(ONTOLOGY + "venue/" + row['identifier'])
        # This is probably wrong and should be http://sws.geonames.org/xxxxxxxx/
        #      geoname = RDF::URI.new("http://www.geonames.org/" + row['geo_id'])
        geoname = RDF::URI.new("http://sws.geonames.org/" + row['geo_id'] + "/")
        
        # Give the node an id so that pubby handles it well. @@Hack.
        sim = RDF::URI.new(ONTOLOGY + "venue/" + row['identifier'] + "/geo-sim" )
        $graph << [sim, type, VOCAB_SIM_SIMILARITY]
        $graph << [sim, VOCAB_SIM_SUBJECT, venue]
        $graph << [venue, VOCAB_SIM_SUBJECT_OF, sim]
        $graph << [sim, VOCAB_SIM_OBJECT, geoname]
        $graph << [geoname, VOCAB_SIM_OBJECT_OF, sim]
        
        # Provenance triple -- this conversion was made by an activity that Sean was responsible for. 
        $graph << [sim, VOCAB_PROV_ATTRIBUTED_TO, SEAN]
        
        if row['lastfm_id'] then
          # Used geo and last fm to crosscheck. 
          $graph << [sim, VOCAB_SIM_METHOD, VOCAB_ETREE_SIMPLE_GEO_AND_LASTFM_MATCH]
        else
          # Only geo information used
          $graph << [sim, VOCAB_SIM_METHOD, VOCAB_ETREE_SIMPLE_GEO_MATCH]
        end
      end
    end
    puts "@@@ Done Chunk #{offset}" if BEHAVIOUR[:verbose]
    offset = offset + 1
  end
  return $graph
end

# Simple geonames information 
def generateGeoDataRDF()
  $graph = RDF::Graph.new

  stmt = LOCATIONS.prepare( 'select distinct geo_id, geo_name, geo_country from locations' )
  rows = stmt.execute()
  gnName = RDF::URI.new("http://www.geonames.org/ontology#name")
  gnCountryCode = RDF::URI.new("http://www.geonames.org/ontology#countryCode")
  
  rows.each do |row|
    if row['geo_id'] != "-----" then
      puts row['geo_id'] if BEHAVIOUR[:debug]
      puts row['geo_name'] if BEHAVIOUR[:debug]
      # This is probably wrong and should be http://sws.geonames.org/xxxxxxxx/
      #geoname = RDF::URI.new("http://www.geonames.org/" + row['geo_id'])
      geoname = RDF::URI.new("http://sws.geonames.org/" + row['geo_id'] + "/")
      $graph << [geoname, gnName, RDF::Literal.new(row['geo_name'])]
      $graph << [geoname, gnCountryCode, RDF::Literal.new(row['geo_country'])]
    end
  end
  return $graph
end

# Simple geonames information 
def generateLastFMDataRDF()
  $graph = RDF::Graph.new

  stmt = LOCATIONS.prepare( 'select distinct lastfm_id, lastfm_name from locations' )
  rows = stmt.execute()
  skos_label = RDF::SKOS.prefLabel
  
  rows.each do |row|
    puts row['lastfm_id'] if BEHAVIOUR[:debug]
    puts row['lastfm_name'] if BEHAVIOUR[:debug]
    if (row['lastfm_id'] && row['lastfm_name']) then
      lastfm = RDF::URI.new("http://www.last.fm/venue/" + row['lastfm_id'])
      $graph << [lastfm, skos_label, RDF::Literal.new(row['lastfm_name'])]
    end
  end
  return $graph
end
