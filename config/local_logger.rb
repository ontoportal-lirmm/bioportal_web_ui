require 'logger'

#THIS is a local logger used mainly by developers

class LocalLogger < Logger
  alias write <<

  def flush
    ((self.instance_variable_get :@logdev).instance_variable_get :@dev).flush
  end
end

# Setup global logging
#USAGE:
# - LOGGER.info("message")
# - LOGGER.error("message")
# - LOGGER.debug("message")
# require 'rack/logger'
# if [:development, :console].include?(settings.environment)
#   #LOGGER = LocalLogger.new(STDOUT)
#   #LOGGER.level = Logger::DEBUG
# else
Dir.mkdir('log') unless File.exist?('log')
log = File.new("log/local_logger.log", "a+")
FileUtils.chown 'ontoportal', 'ontoportal', 'log/local_logger.log' 
log.sync = true
LOGGER = LocalLogger.new(log)

# ============================
#  LOG LEVEL LIST 
# ============================
#  FATAL: An unhandleable error that results in a program crash.
#  ERROR: A handleable error condition.
#  WARN : A warning.
#  INFO : Generic (useful) information about system operation.
#  DEBUG: Low-level information for developers.
# If you set one of the log levels above, the upper levels are also included

LOGGER.level = Logger::DEBUG #DEBUG includes DEBUG, INFO, WARN, ERROR, FATAL log

# use Rack::CommonLogger, log
# end