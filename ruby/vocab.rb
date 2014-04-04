TIMELINE="http://purl.org/NET/c4dm/timeline.owl#"
EVENT="http://purl.org/NET/c4dm/event.owl#"
TIME="http://www.w3.org/2006/time#"
FOAF="http://xmlns.com/foaf/0.1/"
FRBR="http://purl.org/vocab/frbr/core#"
WOT="http://xmlns.com/wot/0.1/" 
BIO="http://purl.org/vocab/bio/0.1/"
MO="http://purl.org/ontology/mo/"
MB="http://musicbrainz.org/"
GEO="http://www.geonames.org/ontology"
SIM="http://purl.org/ontology/similarity/"
PROV="http://www.w3.org/ns/prov#"

ETREE_HOST = "etree.linkedmusic.org"
ETREE = "http://#{ETREE_HOST}/vocab/"

ONTOLOGY = "http://#{ETREE_HOST}/"

VOCAB_MO_PERFORMANCE = RDF::URI.new(MO + "Performance")
VOCAB_ETREE_CONCERT = RDF::URI.new(ETREE + "Concert")
VOCAB_ETREE_TRACK = RDF::URI.new(ETREE + "Track")
VOCAB_ETREE_ID = RDF::URI.new(ETREE + "id")
VOCAB_MO_PERFORMER = RDF::URI.new(MO + "performer")
VOCAB_MO_PERFORMED = RDF::URI.new(MO + "performed")
VOCAB_MO_AUDIOFILE = RDF::URI.new(MO + "AudioFile")
VOCAB_NOTES = RDF::URI.new(ETREE + "notes")
VOCAB_DESCRIPTION = RDF::URI.new(ETREE + "description")
VOCAB_LINEAGE = RDF::URI.new(ETREE + "lineage")
VOCAB_SOURCE = RDF::URI.new(ETREE + "source")
VOCAB_UPLOADER = RDF::URI.new(ETREE + "uploader")
VOCAB_KEYWORD = RDF::URI.new(ETREE + "keyword")
VOCAB_DATE = RDF::URI.new(ETREE + "date")
VOCAB_SUBEVENT = RDF::URI.new(EVENT + "hasSubEvent")
VOCAB_ISSUBEVENTOF = RDF::URI.new(ETREE + "isSubEventOf")
VOCAB_EVENTTIME = RDF::URI.new(EVENT + "time")
VOCAB_TIMEINTERVAL = RDF::URI.new(TIME + "Interval")
VOCAB_TIMELINEBEGINS = RDF::URI.new(TIMELINE + "beginsAtDateTime")
VOCAB_EVENTPLACE = RDF::URI.new(EVENT + "place")
VOCAB_LOCATION = RDF::URI.new(ETREE + "location")
VOCAB_NAME = RDF::URI.new(ETREE + "name")
VOCAB_NUMBER = RDF::URI.new(ETREE + "number")
VOCAB_AUDIO = RDF::URI.new(ETREE + "audio")
VOCAB_VENUE = RDF::URI.new(ETREE + "venue")
VOCAB_VENUECLASS = RDF::URI.new(ETREE + "Venue")
VOCAB_ETREE_MBID = RDF::URI.new(ETREE + "hasMusicBrainzID")
VOCAB_ETREE_SIMPLE_MB_MATCH = RDF::URI.new(ETREE + "simpleMusicBrainzMatch")
VOCAB_ETREE_SIMPLE_LASTFM_MATCH = RDF::URI.new(ETREE + "simpleLastfmMatch")
VOCAB_ETREE_SIMPLE_GEO_MATCH = RDF::URI.new(ETREE + "simpleGeoMatch")
VOCAB_ETREE_SIMPLE_GEO_AND_LASTFM_MATCH = RDF::URI.new(ETREE + "simpleGeoAndLastfmMatch")

VOCAB_SIM_SUBJECT = RDF::URI.new(SIM + "subject")
VOCAB_SIM_OBJECT = RDF::URI.new(SIM + "object")
VOCAB_SIM_SUBJECT_OF = RDF::URI.new(SIM + "subjectOf")
VOCAB_SIM_OBJECT_OF = RDF::URI.new(SIM + "objectOf")
VOCAB_SIM_SIMILARITY = RDF::URI.new(SIM + "Similarity")
VOCAB_SIM_METHOD = RDF::URI.new(SIM + "method")
VOCAB_SIM_WEIGHT = RDF::URI.new(SIM + "weight")
VOCAB_SIM_ASSOCIATION_METHOD = RDF::URI.new(SIM + "AssociationMethod")

VOCAB_PROV_ATTRIBUTED_TO = RDF::URI.new(PROV + "wasAttributedTo")

SEAN = RDF::URI.new(ONTOLOGY + "person/sean-bechhofer")

