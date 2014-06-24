#!/opt/local/bin/ruby
require 'rubygems'
require 'getopt/std'
require 'rdf'
require 'rdf/ntriples'
require 'markaby'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'config'
require 'vocab'
require 'keys'
require 'rbrainz'
require 'db'
#require 'getPerformances'
require 'generatePerformanceRDF'
require 'generateArtistRDF'
require 'generateGeoRDF'
require 'logging'

MB_SLEEP = 1

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

def doPerformanceFile(performance_names,doTracks) 
  File.open(performance_names, "r") do |performance_file|
    artist_performances = {}
    performance_file.each_line do |performance|
      # Pull stuff out of db and build a hash
      debug("DB: Query #{performance}")
      puts "DB: Query #{performance}" if BEHAVIOUR[:verbose]
      stmt = DATABASE.prepare( 'select * from meta where identifier=?' )
      rows = stmt.execute(performance.chomp)
      rows.each do |row|
        debug("DB: #{row['identifier']}")
        puts "DB: #{row['identifier']}" if BEHAVIOUR[:verbose]
        event = {}
        event[:identifier] = row['identifier']
        event[:title] = row['title']
        event[:creator] = row['creator']
        event[:description] = row['description']
        event[:mediatype] = row['mediatype']
        event[:date] = row['date']
        event[:year] = row['year']
        event[:subject] = row['subject']
        event[:venue] = row['venue']
        event[:coverage] = row['coverage']
        event[:source] = row['source']
        event[:lineage] = row['lineage']
        event[:uploader] = row['uploader']
        event[:taper] = row['taper']
        event[:transferer] = row['transferer']
        event[:runtime] = row['runtime']
        event[:notes] = row['notes']
        event[:files] = []
        # Pull file information from db and add to the hash
        debug("DB: Query")
        puts "DB: Query" if BEHAVIOUR[:debug]
        stmt2 = DATABASE.prepare( 'select * from files where event=?' )
        files = stmt2.execute(event[:identifier])
        files.each do |file|
          debug("DB: >> #{file['name']}")
          puts "DB: >> #{file['name']}" if BEHAVIOUR[:debug]
          event[:files] << {
            :name => file['name'],
            :source => file['source'],
            :creator => file['creator'],
            :title => file['title'],
            :album => file['album'],
            :track => file['track'],
            :bitrate => file['bitrate'],
            :length => file['length'],
            :format => file['format'],
            :original => file['original'],
            :md5 => file['md5'],
            :mtime => file['mtime'],
            :size => file['size'],
            :crc32 => file['crc32'],
            :sha1 => file['sha1']
          }
        end # files
        artistName = event[:creator]
        db_checkForArtist(artistName)
        if !artist_performances[artistName] then
          artist_performances[artistName] = []
        end
        puts "Adding event #{event[:title]}" if BEHAVIOUR[:verbose]
        artist_performances[artistName] << event
      end # rows
    end # performance
    puts "STUFF" if BEHAVIOUR[:debug]
#    puts artist_performances.inspect if BEHAVIOUR[:debug]
    puts "END STUFF" if BEHAVIOUR[:debug]
    # Now we have an artist db and a hash that has the performances of
    # various artists. Third argument determines if we want to include
    # tracks.
    graph = generatePerformanceRDF(artist_performances, doTracks)
    puts graph.inspect if BEHAVIOUR[:debug]
    return graph
  end
end

def doArtistPerformances(artist,doTracks) 
  stmt = DATABASE.prepare( 'select * from meta where creator=?' )
  rows = stmt.execute(artist)
  artist_performances = {}

  rows.each do |row|
    puts "DB: #{row['identifier']}" if BEHAVIOUR[:verbose]
    event = {}
    event[:identifier] = row['identifier']
    event[:title] = row['title']
    event[:creator] = row['creator']
    event[:description] = row['description']
    event[:mediatype] = row['mediatype']
    event[:date] = row['date']
    event[:year] = row['year']
    event[:subject] = row['subject']
    event[:venue] = row['venue']
    event[:coverage] = row['coverage']
    event[:source] = row['source']
    event[:lineage] = row['lineage']
    event[:uploader] = row['uploader']
    event[:taper] = row['taper']
    event[:transferer] = row['transferer']
    event[:runtime] = row['runtime']
    event[:notes] = row['notes']
    event[:files] = []
    # Pull file information from db and add to the hash
    puts "DB: Query" if BEHAVIOUR[:debug]
    stmt2 = DATABASE.prepare( 'select * from files where event=?' )
    files = stmt2.execute(event[:identifier])
    files.each do |file|
      puts "DB: >> #{file['name']}" if BEHAVIOUR[:debug]
      event[:files] << {
        :name => file['name'],
        :creator => file['creator'],
        :title => file['title'],
        :album => file['album'],
        :track => file['track'],
        :bitrate => file['bitrate'],
        :length => file['length'],
        :format => file['format'],
        :original => file['original'],
        :md5 => file['md5'],
        :mtime => file['mtime'],
        :size => file['size'],
        :crc32 => file['crc32'],
        :sha1 => file['sha1']
      }
    end # files
    artistName = event[:creator]
    db_checkForArtist(artistName)
    if !artist_performances[artistName] then
      artist_performances[artistName] = []
    end
    puts "Adding event #{event[:title]}" if BEHAVIOUR[:verbose]
    artist_performances[artistName] << event
  end # rows

  puts "STUFF" if BEHAVIOUR[:debug]
  #    puts artist_performances.inspect if BEHAVIOUR[:debug]
  puts "END STUFF" if BEHAVIOUR[:debug]
  # Now we have an artist db and a hash that has the performances of
  # various artists. Third argument determines if we want to include
  # tracks.
  graph = generatePerformanceRDF(artist_performances, doTracks)
  puts graph.inspect if BEHAVIOUR[:debug]
  return graph
end

opt = Getopt::Std.getopts("a:m:o:f:vdhtl:")

$out = nil
$f = nil 
$a = nil
$m = nil
$doTracks = false

if opt["o"] then
  $out = opt["o"]
end
if opt["f"] then
  $f = opt["f"]
end
if opt["a"] then
  $a = opt["a"]
end
if opt["m"] then
  $m = opt["m"]
end
if opt["l"] then
  # DEBUG < INFO < WARN < ERROR < FATAL 
  logLevel(opt["l"])
end
if opt["h"] then
  puts " -o <outputdirectory> performanceIndex"
  puts " -o <outputfile> mbTags"
  puts " -o <outputfile> [-t] -f <indexfile> performanceRDF"
  puts " -o <outputdirectory> [-t] -a <artist name> artistPerformanceRDF"
  puts " -o <outputfile> [artistRDF|lastFMMappingRDF|geoNamesMappingRDF|musicBrainzMappingRDF|musicBrainzTagRDF]"
  exit
end
if opt["t"] then
  $doTracks = true
end
if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end

$command = ARGV[0]

case 
when $command.eql?("performanceRDF")
  if $f then
    info($f)
    puts $f if BEHAVIOUR[:verbose]
    begin
      graph = doPerformanceFile($f,$doTracks)
      RDF::Writer.for(:ntriples).open($out) do |writer|
        graph.each_statement do |statement|
          # Needed to catch the exception in the loop as otherwise the
          # rendering bails and we don't get all of the graph
          # rendered.
          begin 
          writer << statement
          rescue Exception => e 
            logError("Problem Writing: #{e.inspect}")
          end
        end
      end
    rescue Exception => e 
      logError("Problem: #{e.inspect}")
    end
  end
when $command.eql?("artistPerformanceRDF")
  if $a then
    puts $a if BEHAVIOUR[:verbose]
    begin
      graph = doArtistPerformances($a,$doTracks)
      RDF::Writer.for(:ntriples).open($out) do |writer|
        graph.each_statement do |statement|
          writer << statement
        end
      end
    rescue Exception => e 
      logError("Problem: #{e.inspect}")
    end
  end
when $command.eql?("artistRDF")
  graph = generateArtistRDF()
  info("Artist Graph created")
  RDF::Writer.for(:ntriples).open($out) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("lastFMMappingRDF")
  graph = generateLastFMMappingRDF()
  info("Last FM Mapping Graph created")
  RDF::Writer.for(:ntriples).open($out) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("geoNamesMappingRDF")
  graph = generateGeoNamesMappingRDF()
  info("Geo Mapping Graph created")
  RDF::Writer.for(:ntriples).open($out) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("geoDataRDF")
  graph = generateGeoDataRDF()
  info("Geo Graph created")
  RDF::Writer.for(:ntriples).open($out) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("lastFMDataRDF")
  graph = generateLastFMDataRDF()
  info("Last FM Graph created")
  RDF::Writer.for(:ntriples).open($out) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("musicBrainzMappingRDF")
  graph = generateMusicBrainzMappingRDF()
  info("MusicBrainz Mapping Graph created")
  RDF::Writer.for(:ntriples).open($out) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("musicBrainzTagRDF")
  graph = generateMusicBrainzTagRDF()
  info("Music Brainz Tag Graph created")
  RDF::Writer.for(:ntriples).open($out) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("performanceIndex")
  chunk = 1000
  offset = 0
  finished = false
  until finished
    finished = true
    stmt = DATABASE.prepare( "select id from performance limit ? offset ?" )
    rows = stmt.execute(chunk, offset*chunk);
    perfFile = "#{$out}/#{'%03d' % offset}.txt"
    puts perfFile if BEHAVIOUR[:debug]
    File.open(perfFile,'w') do |f|
      rows.each do |row|
        # There was a row, so we're not done yet
        finished = false
        # Write the performance id to the file
        f.puts(row['id'])
      end
    end
    offset = offset +1
  end
when $command.eql?("mbTags")
  $mb = MusicBrainz::Webservice::Webservice.new()
  $q = MusicBrainz::Webservice::Query.new($mb)
  stmt = DATABASE.prepare( "select id, name, mbId from artist NATURAL JOIN musicbrainz where confidence > 0" )
  rows = stmt.execute();
  count = 0
  rows.each do |row|
    puts "#{count}: #{row['id']} | #{row['mbId']} | #{row['name']}" if BEHAVIOUR[:debug]
    result = $q.get_artist_by_id(row['mbId'],{:tags=>true})
    result.tags.each do |tag|
      puts "  > #{tag.text}" if BEHAVIOUR[:debug]
      check = DATABASE.prepare( "select * from mbTags where mbId = ? AND tag = ?" )
      tagPresent = check.execute(row['mbId'],tag.text)
      if tagPresent.next then
        puts "  Already there! " if BEHAVIOUR[:debug]
      else
        ins = DATABASE.prepare( "insert into mbTags (mbId,tag) values (?,?);" )
        ins.execute(row['mbId'],tag.text)
      end
    end
    sleep(MB_SLEEP)
    count = count + 1
  end
else
  puts "Unknown command: #{$command}"
end

