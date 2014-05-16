DB = "/Users/seanb/Documents/etree.database/database.db"
FILES = "/Users/seanb/Documents/etree.source"


def logError(message)
  File.open('errors.log','a') do |f|
    f.puts "#{Time.now}: #{message}"
  end
end
