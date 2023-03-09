# Don't allow downloaded files to be created as tempfiles. Force storage in memory using StringIO.
require "open-uri"
OpenURI::Buffer.send :remove_const, "StringMax" if OpenURI::Buffer.const_defined?("StringMax")
OpenURI::Buffer.const_set "StringMax", 104857600
