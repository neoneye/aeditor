require 'aeditor/backend/convert'
require 'fileutils'

module BufferFile
	def BufferFile.open(filename)
		return [] unless FileTest.exist?(filename)
		File.open(filename) do |file|
			s = file.read
			return Convert.from_string_into_bufferobjs(s)
		end
	end
	# purpose:
	# save file, backup if there is an existing file
	def BufferFile.save(bufobjs, filename, filename_backup)
		s = Convert.from_bufferobjs_into_filestring(bufobjs)
		if FileTest.exist?(filename)
			FileUtils::mv(filename, filename_backup)
			# copy in order to transfer permissions
			FileUtils::cp filename_backup, filename, :preserve => true 
		end
		File.open(filename, 'w') {|f| f.write(s) }
	end
end
