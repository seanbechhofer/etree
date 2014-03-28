require 'rubygems'
require 'sqlite3'
require 'getopt/std'
require 'digest/md5'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'db'

# Get performances that have no metadata, retrieve metadata for that performance, and add it to the database. 
# This won't get file information for those that have metadata but no files. 

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
  puts identifier if (BEHAVIOUR[:verbose] or BEHAVIOUR[:debug])
  begin
    # Pulls metadata from local cache. Assumes it's there! If not,
    # thrown exception should be caught
    digest = Digest::MD5.hexdigest(identifier)
    first = digest[30,1]
    second = digest[31,1]
    cacheLocation = "#{FILES}/#{first}/#{second}/#{identifier}"
    metaURL = "#{cacheLocation}_meta.xml"
    addEventMetadataFile(metaURL)
    fileURL = "#{cacheLocation}_files.xml"
    addEventFilesFile(fileURL,identifier)
    stmt = DATABASE.prepare( "select creator FROM meta where identifier = ?")
    creators = stmt.execute(identifier)
    creators.each do |creator_row|
      puts creator_row['creator'] if (BEHAVIOUR[:verbose] or BEHAVIOUR[:debug])
      db_checkForArtist(creator_row['creator'])
    end
  rescue Exception => e
    if (BEHAVIOUR[:verbose] or BEHAVIOUR[:debug]) then
      puts "Problem!"
      puts identifier
      puts e
    end
  end
end  
