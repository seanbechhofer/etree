#!/opt/local/bin/ruby
require 'rubygems'
require 'getopt/std'
require 'rdf'
require 'rdf/ntriples'
require 'markaby'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'config'
require 'keys'
require 'db'
require 'getPerformances'
require 'generatePerformanceRDF-db'
require 'generateArtistRDF-db'
require 'generateGeoRDF-db'

# Look for -o with argument, and -I and -D boolean arguments
# opt = Getopt::Std.getopts("o:")
# puts opt

# arguments 
# i: input
# o: output
# v: verbose
# d: debug

STYLE = "body {font-family: Gill Sans}
a {text-decoration: none; color: #444}
.banner {font-size: 300%; margin-bottom:10px; text-align: center;}
.performance p {
margin-bottom: 0px;
margin-top: 0px;
}
.artist {font-size:150%; font-weight: bold}
.performance .title {font-size:120%}
.performance .location {margin-left: 10px;}
.performance .files {margin-left: 10px; font-style: italic}
.performance pre {margin-left: 10px;}
"

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

def doPerformanceFile(index,performance_names,out) 
  File.open(performance_names, "r") do |performance_file|
    artist_performances = {}
    performance_file.each_line do |performance|
      # Pull stuff out of db and build a hash
      puts "DB: Query #{performance}" if BEHAVIOUR[:debug]
      stmt = DATABASE.prepare( 'select * from meta where identifier=?' )
      rows = stmt.execute(performance.chomp)
      rows.each do |row|
        puts "DB: #{row['identifier']}" if BEHAVIOUR[:debug]
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
        stmt = DATABASE.prepare( 'select * from files where event=?' )
        files = stmt.execute(event[:identifier])
        files.each do |file|
          puts "DB: >> #{file['identifier']}" if BEHAVIOUR[:debug]
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
        artist_performances[artistName] << event
      end # rows
    end # performance
    puts artist_performances.inspect if BEHAVIOUR[:debug]
    id = index.sub("/","-")
    # Now we have an artist db and a hash that has the performances of
    # various artists. Third argument determines if we want to include
    # tracks.
    graph = generatePerformanceRDF(artist_performances, $doTracks)
    puts graph.inspect if BEHAVIOUR[:debug]
    # Write the graph
    if out then
      RDF::Writer.for(:ntriples).open("#{$o}/#{id}.nt") do |writer|
        graph.each_statement do |statement|
          writer << statement
        end
      end
    end
  end
end

opt = Getopt::Std.getopts("m:o:f:vdht")

$o = nil
$f = nil 
$m = nil
$doTracks = false

if opt["o"] then
  $o = opt["o"]
end
if opt["f"] then
  $f = opt["f"]
end
if opt["m"] then
  $m = opt["m"]
end
if opt["h"] then
  puts " -o <outputdirectory> [-t] [-f <indexfile>|-m <month>] performanceRDF"
  puts " -o <outputfile> [generateArtistRDF|generateLastFMMappingRDF|generateGeoNamesMappingRDF|generateMusicBrainzMappingRDF]"
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
    puts $f if BEHAVIOUR[:verbose]
    begin
      File.open($f,"r") do |file|
        file.each_line do |line|
          # files should be of the form year/month
          index = line.chomp
          performance_names = "files/#{index}/index.txt"
          puts performance_names if BEHAVIOUR[:verbose]
          base = "files/#{index}"
          begin
            doPerformanceFile(index,performance_names,$o)
          rescue Exception => e 
            logError("Problem: #{e.inspect}")
          end
        end
      end
    rescue Exception => e 
      logError("Problem: #{e.inspect}")
    end
  end
  if $m then
    performance_names = "files/#{$m}/index.txt"
    puts performance_names if BEHAVIOUR[:verbose]
    base = "files/#{$m}"
    begin
      doPerformanceFile($m,performance_names,$o)
    rescue Exception => e 
      logError("Problem: #{e.inspect}")
    end
  end
when $command.eql?("generateArtistRDF")
  graph = generateArtistRDF()
  RDF::Writer.for(:ntriples).open($o) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("generateLastFMMappingRDF")
  graph = generateLastFMMappingRDF()
  RDF::Writer.for(:ntriples).open($o) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("generateGeoNamesMappingRDF")
  graph = generateGeoNamesMappingRDF()
  RDF::Writer.for(:ntriples).open($o) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("generateGeoDataRDF")
  graph = generateGeoDataRDF()
  RDF::Writer.for(:ntriples).open($o) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("generateLastFMDataRDF")
  graph = generateLastFMDataRDF()
  RDF::Writer.for(:ntriples).open($o) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
when $command.eql?("generateMusicBrainzMappingRDF")
  graph = generateMusicBrainzMappingRDF()
  RDF::Writer.for(:ntriples).open($o) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
else
  puts "Unknown command: #{$command}"
end

