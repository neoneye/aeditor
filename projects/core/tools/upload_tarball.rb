# Release File by uploading to sf.net/incoming
#
# Copyright (c) 2001-2003 Simon Strandgaard
#
# See the file "LICENSE" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# $Id: upload_tarball.rb,v 1.1 2003/07/01 11:18:15 neoneye Exp $
require 'net/ftp'

$upload_url = "upload.sourceforge.net"

def upload_files(filenames)
	puts "files to upload: #{filenames}"
	print "connecting to #{$upload_url} ... "
	$stdout.flush
	ftp = Net::FTP.new($upload_url)
	ftp.login
	ftp.chdir("/")
	ftp.chdir("incoming")
	puts "OK"
	filenames.each do |filename|
		print "uploading file \"#{filename}\" ... "
		$stdout.flush
		ftp.putbinaryfile(filename, filename, 1024)
		if ftp.dir(filename).size == 0
			throw "could not upload file"
		end
		puts "OK"
	end
	ftp.close
	puts "uploading completed"
rescue
	print "ERROR: " + $! + "\n"
end

if $0 == __FILE__
	if ARGV.size == 0
		files = Dir["*.tar.gz"]
	else
		files = ARGV
	end
	upload_files(files)
end
