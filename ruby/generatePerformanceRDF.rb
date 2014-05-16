# Takes hashes, one of performances, one of artists and then
# generates rdf.
# Expected form of the artists hash is:
#
# The Schwillbillies: 
#  :type: :artist
#  :mb_id: 533fe050-73c8-4c07-9720-65ed9b4fd7dc
#  :id: 4229a560-4aac-012f-19e9-00254bd44c28
# ...
# 
# where mb_id: is the musicbrainz id of the artist.
# 
# Expected form of the performances hash is:

# Mogwai: 
# - format: 
#  - 24bit Flac
#  - Checksums
#  - Flac FingerPrint
#  - Metadata
#  - Text
#  - Unknown
#  coverage: 
#   - Melbourne, AU
#  avg_rating: 0.0
#  month: 3
#  week: 0
#  downloads: 90
#  num_reviews: 0
#  ...

# The approach here is very naive. Every performance gets a unique
# identifier for its venue. The idea is that we'll do all the RDF
# generation, then refine at a later date. This may not be an optimal
# solution!!

require 'rubygems'
require 'net/http'
require 'json'
require 'yaml'
require 'csv'
require 'rbrainz'
require 'getopt/std'
require 'rdf'
require 'rdf/ntriples'
require 'uuid'
require 'config'
require 'db'

def generatePerformanceRDF(performances, doTracks) 
  begin
    if !(performances) then
      puts "Need performances "
      exit
    end
    uuid = UUID.new
    $graph = RDF::Graph.new
    
    performances.each do |k,v|
      # k is the name of an artist, v is a list of hashes with information about gigs
      stmt = DATABASE.prepare( 'select id from artist where name=?' )
      rows = stmt.execute(k)
      # Assume there's a result.
      artist_id = rows.next()['id']
      #      artist_id = artists[k][:id]
      puts k if BEHAVIOUR[:verbose]
      puts artist_id if BEHAVIOUR[:verbose]
      puts performances[k].inspect if BEHAVIOUR[:debug]
      performances[k].each do |perf|
        # Get a new id
        # performance_id = uuid.generate
        performance_id = perf[:identifier]
        
        performance = RDF::URI.new(ONTOLOGY + "performance/" + performance_id)
        artist = RDF::URI.new(ONTOLOGY + "artist/" + artist_id)
        
        type = RDF.type

        $graph << [performance, type, VOCAB_MO_PERFORMANCE]
        $graph << [performance, type, VOCAB_ETREE_CONCERT]

        $graph << [performance, VOCAB_ETREE_ID, RDF::Literal.new(perf[:identifier])] if perf[:identifier]
        
        $graph << [performance, VOCAB_NOTES, RDF::Literal.new(perf[:notes])] if perf[:notes]
        
        $graph << [performance, VOCAB_DESCRIPTION, RDF::Literal.new(perf[:description])] if perf[:description]
        
        $graph << [performance, VOCAB_LINEAGE, RDF::Literal.new(perf[:lineage])] if perf[:lineage]
        
        $graph << [performance, VOCAB_SOURCE, RDF::Literal.new(perf[:source])] if perf[:source]

        $graph << [performance, VOCAB_UPLOADER, RDF::Literal.new(perf[:uploader])] if perf[:uploader]

        keywords = []
#        keywords = perf[:subject].split(";") if perf[:subject]
        #Fixing split on commas and semicolons
        keywords = perf[:subject].split(/\s*[,;]\s*/) if perf[:subject]

        keywords.each do |kw|
          $graph << [performance, VOCAB_KEYWORD, RDF::Literal.new(kw.strip)] 
        end
        
        $graph << [performance, VOCAB_MO_PERFORMER, artist]
        $graph << [artist, VOCAB_MO_PERFORMED, performance]
        
#        subEvent = RDF::URI.new(EVENT + "hasSubEvent")
#        isSubEventOf = RDF::URI.new(ETREE + "isSubEventOf")
        
        puts perf[:title] if BEHAVIOUR[:verbose]
        skos_label = RDF::SKOS.prefLabel
        see_also = RDF::RDFS.seeAlso

        $graph << [performance, skos_label, RDF::Literal.new(perf[:title])] if perf[:title]

        # Link to archive.org details.
        iaDetails = RDF::URI.new("http://archive.org/details/" + performance_id)
        $graph << [performance, see_also, iaDetails]
        
        # Just using start date
        if perf[:date] then
          timeNode = RDF::Node.new
          # eventTime = RDF::URI.new(EVENT + "time")
          # timeInterval = RDF::URI.new(TIME + "Interval")
          
          # Add date as a string
          $graph << [performance, VOCAB_DATE, RDF::Literal.new(perf[:date])]

          # Attempt to parse the date. If succesful, add it
          begin
            $graph << [performance, VOCAB_EVENTTIME, timeNode]
            $graph << [timeNode, type, VOCAB_TIMEINTERVAL]
            date = Date.parse(perf[:date])
            
            $graph << [timeNode, VOCAB_TIMELINEBEGINS, RDF::Literal.new(date.to_s, :datatype => RDF::XSD.date)]
          rescue Exception => ex
            puts ("Date Problem: #{perf[:date]}, #{performance_id} " +  ex.inspect) if BEHAVIOUR[:debug]
            logError("Date Problem: #{perf[:date]}, #{performance_id} " +  ex.inspect)
          end
        end
                
        if perf[:venue] then
          # Generate a new node for the venue. Doesn't attempt to match up duplicates. 
          #venue_id = uuid.generate
          venueNode = RDF::URI.new(ONTOLOGY + "venue/" + performance_id)
          $graph << [performance, VOCAB_EVENTPLACE, venueNode]
          $graph << [venueNode, type, VOCAB_VENUECLASS]
          $graph << [venueNode, skos_label, RDF::Literal.new(perf[:venue])] 
          $graph << [venueNode, VOCAB_NAME, RDF::Literal.new(perf[:venue])] 
          # This is a weird one. Attribute coverage is actually the place
          if perf[:coverage] then
            # Rather than creating a new node, just add the location as a string.
            $graph << [venueNode, VOCAB_LOCATION, RDF::Literal.new(perf[:coverage])] 
            # Create a new node for the location. Again, no attempt to match duplicates.
            # location_id = uuid.generate
            # locationNode = RDF::URI.new(ONTOLOGY + "location/" + location_id)
            # $graph << [venueNode, location, locationNode] 
            # $graph << [locationNode, type, locationClass]
            # $graph << [locationNode, skos_label, RDF::Literal.new(perf[:coverage])]
          end # :coverage
        end # :venue

        if doTracks then 
          tracks = {}
          # Add resources for each song/track played. This assumes that
          # anything that's got a track number corresponds to a track
          # played. 
          
          # We probably also want to identify the particular sound files that correspond to the audio for that track. 
          if perf[:files] then
            perf[:files].each do |file| 
              puts file[:name] if BEHAVIOUR[:verbose]
              # title, track, format, name
              # Initialise the tracks hash with empty things for each track 
              if file[:track] then 
                puts "Creating Track #{file[:track]}" if BEHAVIOUR[:verbose]
                begin
                  trackNum = file[:track].to_i
                  if trackNum!=0 then
                    tracks[trackNum] = {
                      :number => trackNum,
                      :versions => []
                    }
                  end
                rescue Exception => ex
                  logError("Track Number Conversion: " + ex.inspect)
                  puts ("Track Number Conversion: " + ex.inspect) if BEHAVIOUR[:debug]
                end
              end
            end
            
            tracks.each do |num, track|
              perf[:files].each do |file|
                begin
                  fileNum = file[:track].to_i
                  if fileNum == num then
                    tracks[num][:title] = file[:title]
                    if file[:format] && file[:name] then
                      tracks[num][:versions] << 
                        {
                        :format => file[:format], 
                        :name => file[:name], 
                        :source => file[:source],
                        :original => file[:original]
                      }
                    end
                  end
                rescue Exception => ex
                  logError("Track Number Conversion: " + ex.inspect)
                  puts ("Track Number Conversion: " + ex.inspect) if BEHAVIOUR[:debug]
                end
              end # :files
            end # :trackNumbers
            
            # Now we have a hash with all the stuff in it. 
            tracks.each do |trackNum,v|
              track_id = "#{performance_id}-#{trackNum}"
              #track_id = uuid.generate
              if tracks[trackNum][:number] then
                puts tracks[trackNum][:number] if BEHAVIOUR[:verbose]
                trackNode = RDF::URI.new(ONTOLOGY + "track/" + track_id)
                $graph << [trackNode, type, VOCAB_MO_PERFORMANCE]
                $graph << [trackNode, type, VOCAB_ETREE_TRACK]
                $graph << [trackNode, VOCAB_MO_PERFORMER, artist]
                $graph << [performance, VOCAB_SUBEVENT, trackNode]
                $graph << [trackNode, VOCAB_ISSUBEVENTOF, performance]
                $graph << [trackNode, skos_label, tracks[trackNum][:title]] if tracks[trackNum][:title]
                $graph << [trackNode, VOCAB_NUMBER, tracks[trackNum][:number]]
                # Add a reference to the audio file 
                tracks[trackNum][:versions].each do |version|
                  puts "@@Download links" if BEHAVIOUR[:debug]
                  audioNode = RDF::URI.new("http://archive.org/download/" + performance_id + "/" + version[:name])
                  $graph << [trackNode, VOCAB_AUDIO, audioNode]
                  # Type the file
                  $graph << [audioNode, type, VOCAB_MO_AUDIOFILE]

                  # Add format information (as literal)
                  $graph << [audioNode, VOCAB_AUDIOFORMAT, RDF::Literal.new(version[:format])] if version[:format]
                  
                  # Add information about whether it is original or derived
                  if version[:source] then
                    if version[:source] == "original" then
                      $graph << [audioNode, VOCAB_AUDIODERIVATIONSTATUS, VOCAB_AUDIODERIVATIONORIGINAL]
                    elsif version[:source] == "derivative" then
                      $graph << [audioNode, VOCAB_AUDIODERIVATIONSTATUS, VOCAB_AUDIODERIVATIONDERIVED]
                    end
                  end
                  # If there is information about the original audio, include that in the derived RDF
                  # This probably needs work...
                  if version[:source] == "derivative" then
                    originalNode = RDF::URI.new("http://archive.org/download/" + performance_id + "/" + version[:original])
                    $graph << [audioNode, VOCAB_AUDIODERIVEDFROM, originalNode]
                    $graph << [originalNode, type, VOCAB_MO_AUDIOFILE]
                  end
                end
                # Also need to add various things about the files etc. 
              end
            end # tracks
          end
        end
      end
    end
    
    puts $graph.inspect if BEHAVIOUR[:debug]
    $graph.each_statement do |statement|
      puts statement.inspect if BEHAVIOUR[:debug]
    end
    return $graph
  rescue Exception => ex
    logError("Problem Generating RDF:")
    logError(ex.message)
  end
end
