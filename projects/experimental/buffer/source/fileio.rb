require 'fileutils'

module FileHelper
	def check_content(filename, content)
		return true unless filename
		return true unless File.exist?(filename)
		(IO.read(filename) != content)
	end
	def find_dir_in_path(name)
		$:.each do |location|
			next unless FileTest.directory?(location)
			absolute_location = File.expand_path(location)
			Dir[File.join(absolute_location, '**')].each do |path|
				next unless FileTest.directory?(path)
				return path if File.basename(path) === name
			end
		end
		nil
	end
	extend self
end # class FileHelper

class FileSaver
	def initialize
		@backup_suffix = '.bak'
	end
	attr_reader :backup_suffix
	def backup_before_save(name)
		return unless File.exist?(name)
		name_backup = name + @backup_suffix
		if FileTest.symlink?(name)
			# make a local backup
			FileUtils::copy(name, name_backup, :preserve=>true)
		elsif File.exist?(name)
			stat = File.stat(name)
			FileUtils::move(name, name_backup)
			# create empty file with same permissions, and then 
			# output content to it, are much more secure than 
			# changing permissions after creating the file.
			FileUtils::touch name
			File.chmod(stat.mode, name)
		end 
	end
	def check_permissions(name)
		return unless File.exist?(name)

		if FileTest.symlink?(name)
			unless FileTest.writable?(name)
				real_name = File.readlink(name)
				raise "you don't have permission to write to " +
					"the symlink #{name.inspect} -> #{real_name.inspect}."
			end
		else
			unless FileTest.writable?(name)
				raise "you don't have permission to write to " +
					"the file #{name.inspect}."
			end
		end
	end
	def save(name, content)
		check_permissions(name)
		backup_before_save(name)
		begin
			File.open(name, 'w+') do |f|
				f.write(content)
			end
		rescue Errno::EACCES => e
			raise "could not create the file #{name.inspect}"
		end
	end
	def self.save(name, content)
		self.new.save(name, content)
	end
end
