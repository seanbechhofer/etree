# Reads a hash and then generates rdf
# Expected form of the hash is:
#
# The Schwillbillies: 
#  :type: :artist
#  :mb_id: 533fe050-73c8-4c07-9720-65ed9b4fd7dc
#  :id: 4229a560-4aac-012f-19e9-00254bd44c28
# 
# where mb_id: is the musicbrainz id of the artist.

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

def generateArtistRDF()
  $graph = RDF::Graph.new
  
  # Hack to give something we can browse 
  
  collection = RDF::URI.new(ONTOLOGY + "collection")
  contains = RDF::URI.new(ETREE + "contains")
  
  stmt = DATABASE.prepare( "select id, name from artist" )
  rows = stmt.execute()
  rows.each do |row|
    puts row['name'] if BEHAVIOUR[:debug]
    artist = RDF::URI.new(ONTOLOGY + "artist/" + row['id'])
    type = RDF.type
    mo_artist = RDF::URI.new(MO + "MusicArtist")
    foaf_name = RDF::FOAF.name
    skos_label = RDF::SKOS.prefLabel
    
    $graph << [artist, type, mo_artist]
    $graph << [artist, foaf_name, RDF::Literal.new(row['name'])]
    $graph << [artist, skos_label, RDF::Literal.new(row['name'])]
    
    # Adding artists into the collection
    # $graph << [collection, contains, artist]
  end
  return $graph
end

def generateMusicBrainzMappingRDF()
  $graph = RDF::Graph.new

  stmt = DATABASE.prepare( 'select id, mbId, confidence from musicbrainz' )
  rows = stmt.execute()
  type = RDF.type

  rows.each do |row|
    puts row['name'] if BEHAVIOUR[:debug]
    if (row['confidence']) > 0 then
      artist = RDF::URI.new(ONTOLOGY + "artist/" + row['id'])
      # Use #_ for NIR
      puts "X"
      mbId = RDF::URI.new(MB + "artist/" + row['mbId'] + "#_")
      # Give the node an id so that pubby handles it well. @@Hack.
      sim = RDF::URI.new(ONTOLOGY + "artist/" + row['id'] + "/mb-sim")
      $graph << [sim, type, VOCAB_SIM_SIMILARITY]
      $graph << [sim, VOCAB_SIM_SUBJECT, artist]
      $graph << [artist, VOCAB_SIM_SUBJECT_OF, sim] 
      $graph << [sim, VOCAB_SIM_OBJECT, mbId]
      $graph << [mbId, VOCAB_SIM_OBJECT_OF, sim] 
      $graph << [sim, VOCAB_SIM_METHOD, VOCAB_ETREE_SIMPLE_MB_MATCH]
      $graph << [sim, VOCAB_SIM_WEIGHT, RDF::Literal.new(row['confidence'], :datatype => RDF::XSD.double)]

      # Provenance triple -- this conversion was made by an activity that Sean was responsible for. 
      $graph << [sim, VOCAB_PROV_ATTRIBUTED_TO, SEAN]

    end
  end
  return $graph
end

# Check to see if this key is there. If not, generate a new entry with an id. 
def checkForArtistinDB(artistName) 
  stmt = DATABASE.prepare( 'select id from artist where name=?' )
  rows = DATABASE.execute(artistName)
  if !rows.next() then
    uuid = UUID.new
    new_id = uuid.generate
    stmt = DATABASE.prepare( 'insert into artist (id, name) values (?,?)' )
    stmt.execute(new_id, artistName)
  end
end


