require 'rubygems'
require 'sqlite3'
require 'getopt/std'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'db'
require 'digest/md5'

# Get performances that have no metadata, retrieve metadata for that performance, and cache it locally. 

# The metadata files are held in a collection of nested
# directories. To determine which directory to find the metadata for a
# performance <id>, calculate the MD5 hash of <id>, and take the last
# two hex digits. This give the parent and subdirectory where things
# are found. For example,

# md5("performance79") = 12414cda1cd817b13186bf849fa2c138

# So the metadata files for performance79 as found in directory FILES/3/8

#LIMIT = "LIMIT 10000 OFFSET 50000"
LIMIT = ""

BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

opt = Getopt::Std.getopts("vd")
if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end

query = "select id FROM performance #{LIMIT}"
stmt = DATABASE.prepare( query )
rows = stmt.execute()

count = 0
good = 0
bad = 0
rows.each do |row|
  count = count + 1
  identifier = row['id']
#  puts identifier if (BEHAVIOUR[:verbose] or BEHAVIOUR[:debug])
  begin
    found = false
    digest = Digest::MD5.hexdigest(identifier)
    first = digest[30,1]
    second = digest[31,1]
    local_meta = "#{FILES}/#{first}/#{second}/#{identifier}_meta.xml"
    local_files = "#{FILES}/#{first}/#{second}/#{identifier}_files.xml"
    if !File.exist?(local_meta) then
      found = true
      metaURL = "http://www.archive.org/download/#{identifier}/#{identifier}_meta.xml"
      File.open(local_meta, 'w') {|l_m|
        open(metaURL) {|mU|
          mU.each_line {|line|
            l_m.write(line)
          }
        }
      }
      print "Downloaded: #{identifier} meta to #{local_meta}\n"
    end
    if !File.exist?(local_files) then
      found = true
      filesURL = "http://www.archive.org/download/#{identifier}/#{identifier}_files.xml\n"
      File.open(local_files, 'w') {|l_f|
        open(filesURL) {|fU|
          fU.each_line {|line|
            l_f.write(line)
          }
        }
      }
      print "Downloaded: #{identifier} files to #{local_files}\n"
    end
    # if (found) then
    #   puts ""
    # end
#    print "#{count} "
    $stdout.flush
  rescue Exception => e
#    if (BEHAVIOUR[:verbose] or BEHAVIOUR[:debug]) then
      puts "Problem!"
      puts identifier
      puts e
#    end
  end
end  
