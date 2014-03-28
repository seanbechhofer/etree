require 'rubygems'
require 'sqlite3'
require 'getopt/std'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'db'

# Report on those performances that have no metadata in the database. 

# Limit the query if necessary. If this is used, we'll need to re-run this script multiple times. 
#LIMIT = "limit 20000"
LIMIT=""
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

query = "select id FROM (select id, identifier from performance LEFT JOIN meta ON performance.id = meta.identifier) WHERE identifier is null #{LIMIT}"
stmt = DATABASE.prepare( query )
rows = stmt.execute()

count = 0
rows.each do |row|
  identifier = row['id']
  puts identifier
end  
