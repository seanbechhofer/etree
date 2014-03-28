require 'rubygems'
require 'sqlite3'
require 'getopt/std'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'db'
require 'digest/md5'

# Report performances that have no metadata cached locally. 

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
  puts identifier if (BEHAVIOUR[:verbose] or BEHAVIOUR[:debug])
  begin
    found = false
    digest = Digest::MD5.hexdigest(identifier)
    first = digest[30,1]
    second = digest[31,1]
    local_meta = "#{FILES}/#{first}/#{second}/#{identifier}_meta.xml"
    local_files = "#{FILES}/#{first}/#{second}/#{identifier}_files.xml"
    m = !File.exist?(local_meta)
    f = !File.exist?(local_files)
    if (m && f) then
      puts "MF: #{identifier}"
    elsif m then
      puts "M:  #{identifier}"
    elsif f then
      puts "F:  #{identifier} "
    end
  rescue Exception => e
#    if (BEHAVIOUR[:verbose] or BEHAVIOUR[:debug]) then
      puts "Problem!"
      puts identifier
      puts e
#    end
  end
end  
