require 'rubygems'
require 'getopt/std'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'db'

# Takes an XML metadata file and puts the contents into a local db. 
def addMonth(month)
  begin
    # files should be of the form year/month
    index = month
    performance_names = "files/#{index}/index.txt"
    puts performance_names if BEHAVIOUR[:verbose]
    base = "files/#{index}"
    begin
      File.open(performance_names, "r") do |performance_file|
        artist_performances = {}
        performance_file.each_line do |performance|
          puts "#{base}/#{performance.chomp}_meta.xml" if BEHAVIOUR[:verbose]
          puts "#{base}/#{performance.chomp}_files.xml" if BEHAVIOUR[:verbose]
          begin
            addEventMetadataFile("#{base}/#{performance.chomp}_meta.xml")
          rescue Exception => e
            puts "Problem #{e.inspect}"
          end
          begin
            addEventFilesFile("#{base}/#{performance.chomp}_files.xml","#{performance.chomp}")
          rescue Exception => e
            puts "Problem #{e.inspect}"
          end
        end
      end
    end
  rescue Exception => ex
    puts "Problem: #{month}"
    puts ex.inspect
  end
end

opt = Getopt::Std.getopts("f:m:vd")

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

if opt["f"] then
  $f = opt["f"]
end
if opt["m"] then
  $m = opt["m"]
end
if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end

$command = ARGV[0]

case
when $command.eql?("initialise") 
  initialise()
when $command.eql?("add")
  if $f then
    File.open($f,"r") do |file|
      file.each_line do |line|
        addMonth(line.chomp)
      end
    end
  end
  if $m then
    addMonth($m)
  end
when $command.eql?("addArtists")
  puts "Adding: #{$f}" if BEHAVIOUR[:verbose]
  addArtists($f)
end


