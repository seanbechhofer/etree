# Reads a list of names and checks for matches in
# musicbrainz. Anything that has a single match that is identical is
# stored in a hash.

# WARNING! This can take a loooong time. Ideally, this script should only be run once. 

require 'rubygems'
require 'net/http'
require 'json'
require 'csv'
require 'rbrainz'
require 'getopt/std'
require 'amatch'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'db'


BEHAVIOUR = {
  :debug => false,
  :verbose => false
}

THRESHOLD = 0.9
# Sleep to avoid locking out by musicbrainz.
MB_SLEEP = 2

opt = Getopt::Std.getopts("vd")
if opt["v"] then
  BEHAVIOUR[:verbose] = true
end
if opt["d"] then
  BEHAVIOUR[:debug] = true
end

# $mb = MusicBrainz::Webservice::Webservice.new(
#                                             :host => '192.168.56.101',
#                                             :port => '3000'
#                                             )

$mb = MusicBrainz::Webservice::Webservice.new()
$q = MusicBrainz::Webservice::Query.new($mb)

stmt = DATABASE.prepare( 'select id, name from artist' )
rows = stmt.execute()
rows.each do |row|
  artist = row['name']
  if (!artist.empty?) then
    # Is it done already?
    stmt = DATABASE.prepare( 'select id, mbId from musicbrainz where id=?')
    matches = stmt.execute(row['id'])
    match = matches.next()
    if match then
      puts "#{artist}: #{match['mbId']}" if BEHAVIOUR[:debug]
    else
      # Need to sleep so we don't hammer Musicbrainz and get locked out.
      sleep(MB_SLEEP)
      
      args = {
        :name => artist
      }
      
      puts "#{artist}" if BEHAVIOUR[:verbose]
      
      begin 
        results = $q.get_artists(args)
        puts "query ok"
        details = nil
        puts "#{results.entities.length} results" if BEHAVIOUR[:verbose]
        top100 = []
        results.each do |result|
          #        puts "#{result.entity.name}"
          if result.score == 100 then
            top100 << result
          end
        end
        if top100.length == 1 then
          $tiptop = nil
          puts "singleton" if BEHAVIOUR[:verbose]
          $tiptop = top100[0]
          puts "#{artist} <=> #{$tiptop.entity.name}" if BEHAVIOUR[:verbose]
          if $tiptop.entity.name.eql?(artist)
            puts "match" if BEHAVIOUR[:verbose]
            puts $tiptop.entity.id.uuid if BEHAVIOUR[:verbose]
            details = {
              :mb_id => $tiptop.entity.id.uuid,
              :type => $tiptop.entity.id.entity
            }
          end
          matcher = Amatch::Jaro.new(artist)
          jaro_match = matcher.match($tiptop.entity.name)
          # If we're above the threshold, insert into DB.
          if jaro_match > THRESHOLD then
            puts "#{artist} matches #{$tiptop.entity.name}, #{jaro_match}" if BEHAVIOUR[:verbose]
            inserter = DATABASE.prepare( 'insert into musicbrainz (id,mbId,confidence) values (?,?,?)' )
            inserter.execute(row['id'],$tiptop.entity.id.uuid,jaro_match) 
          else
            # No good results, so bang in a placeholder
#            inserter = DATABASE.prepare( 'insert into musicbrainz (id,mbId,confidence) values (?,?,?)' )
 #           inserter.execute(row['id'],"-----",0)
          end
        else
          # No top results, so bang in a placeholder
#          inserter = DATABASE.prepare( 'insert into musicbrainz (id,mbId,confidence) values (?,?,?)' )
#          inserter.execute(row['id'],"-----",0)
        end
      rescue MusicBrainz::Webservice::ConnectionError => e
        puts "Problem with #{artist}"
        puts e
      rescue MusicBrainz::Webservice::RequestError => e
        puts "Problem with #{artist}"
        puts e
      rescue Exception => e
        puts "Problem with #{artist}" 
        puts e
      end
    end
  end
end 
