require "open-uri"
require "digest/sha1"

class RemoteFile < ::Tempfile
  def initialize(path, name = nil, tmpdir = Dir::tmpdir)
    @original_filename = name.nil? ? File.basename(path) : name
    @remote_path = path

    super Digest::SHA1.hexdigest(path), tmpdir
    fetch
  end

  def fetch
    string_io = OpenURI.send(:open, @remote_path)
    self.write string_io.read
    self.rewind
    self
  end

  def original_filename
    @original_filename
  end

  def content_type
    mime = `file --mime -br #{self.path}`.strip
    mime = mime.gsub(/^.*: */, "")
    mime = mime.gsub(/;.*$/, "")
    mime = mime.gsub(/,.*$/, "")
    mime
  end
end
