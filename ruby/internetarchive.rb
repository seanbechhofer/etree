class InternetArchiveEntry
  attr_accessor :avg_rating, :call_number, :collection, :contributor, :coverage, :creator, 
  :date, :description, :downloads, :foldoutcount, :format, :headerimage, :identifier, 
  :imagecount, :language, :licenseurl, :mediatype, :month, :num_reviews, :oai_updatedate, 
  :publicdate, :publisher, :rights, :scanningcentre, :source, :subject, :title, :type, 
  :volume, :week, :year, :musicbrainz_artist, :files

  def self.header(csv)
    csv << [
            'avg_rating',
            'call_number',
            'collection',
            'contributor',
            'coverage',
            'creator',
            'date',
            'description',
            'downloads',
            'foldoutcount',
            'format',
            'headerimage',
            'identifier',
            'imagecount',
            'language',
            'licenseurl',
            'mediatype',
            'month',
            'num_reviews',
            'oai_updatedate',
            'publicdate',
            'publisher',
            'rights',
            'scanningcentre',
            'source',
            'subject',
            'title',
            'type',
            'volume',
            'week',
            'year',
            'musicbrainz_artist'
           ]
  end

  def self.dump_csv(data, file)
    csvfile = File.open(file,'w')
    CSV::Writer.generate(csvfile) do |csv|
      header(csv)
      data.each do |datum|
        datum.to_csv(csv)
      end
    end
  end

  def self.dump_yaml(data, file)
    File.open(file,'w') do |f|
      f.puts $data.to_yaml
    end
  end

  def self.dump_json(data, file)
    File.open(file,'w') do |f|
      f.puts $data.to_json
    end
  end
      
  def initialize(hash)
    @avg_rating = hash['avg_rating']
    @call_number = hash['call_number']
    @collection = hash['collection']
    @contributor = hash['contributor']
    @coverage = hash['coverage']
    @creator = hash['creator']
    @date = hash['date']
    @description = hash['description']
    @downloads = hash['downloads']
    @foldoutcount = hash['foldoutcount']
    @format = hash['format']
    @headerimage = hash['headerimage']
    @identifier = hash['identifier']
    @imagecount = hash['imagecount']
    @language = hash['language']
    @licenseurl = hash['licenseurl']
    @mediatype = hash['mediatype']
    @month = hash['month']
    @num_reviews = hash['num_reviews']
    @oai_updatedate = hash['oai_updatedate']
    @publicdate = hash['publicdate']
    @publisher = hash['publisher']
    @rights = hash['rights']
    @scanningcentre = hash['scanningcentre']
    @source = hash['source']
    @subject = hash['subject']
    @title = hash['title']
    @type = hash['type']
    @volume = hash['volume']
    @week = hash['week']
    @year = hash['year']
    @musicbrainz_artist = []
    @files = []
  end

  def to_s 
    return "#{@title}"
  end

  def to_csv(csv)
    if @musicbrainz_artist == nil then
      @musicbrainz_artist = []
    end
    csv << [
            @avg_rating,
            @call_number,
            @collection,
            @contributor,
            @coverage,
            @creator,
            @date,
            @description,
            @downloads,
            @foldoutcount,
            @format,
            @headerimage,
            @identifier,
            @imagecount,
            @language,
            @licenseurl,
            @mediatype,
            @month,
            @num_reviews,
            @oai_updatedate,
            @publicdate,
            @publisher,
            @rights,
            @scanningcentre,
            @source,
            @subject,
            @title,
            @type,
            @volume,
            @week,
            @year,
            list(@musicbrainz_artist)
           ]
  end

  def list(list)
#    result = "["
    result = ""
    $first = true
    list.each do |l|
      if !$first then 
        result = result + " | "
     end
      $first = false
      result = result + l.to_s
    end
#    result = result + "]"
    return result
  end

  def name_matches
    return (@musicbrainz_artist.size != nil) && 
      (@musicbrainz_artist.size == 1) &&
      (@musicbrainz_artist[0].name.eql?(@creator[0])) 
  end
end

class InternetArchiveFile
  attr_accessor :creator, :title, :track, :musicbrainz_track
  def initialize(hash) 
    @creator = hash[:creator]
    @title = hash[:title]
    @track = hash[:track]
    @musicbrainz_track = []
  end
  
end

class InternetArchiveArtist
  attr_accessor :name, :mb_id

  def initialize(name)
    @name = name
  end

  def to_s 
    return "#{@name} (#{mb_id})"
  end
end

  
