require 'log4r'

# Logging

include Log4r

# DEBUG < INFO < WARN < ERROR < FATAL 
$logger = Logger.new('logger')
$logger.outputters = Outputter.stdout
$logger.level = FATAL

def debug(message)
  $logger.debug(message)
end

def info(message)
  $logger.info(message)
end

def warn(message)
  $logger.warn(message)
end

def logLevel(lev)
    if lev.eql?("DEBUG") then
    $logger.level = DEBUG
  elsif lev.eql?("INFO") then
    $logger.level = INFO
  elsif lev.eql?("WARN") then
    $logger.level = WARN
  elsif lev.eql?("ERROR") then
    $logger.level = ERROR
  elsif lev.eql?("FATAL") then
    $logger.level = FATAL
  end    
end
