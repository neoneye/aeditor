# purpose:
# build a release: tgz, gem, zip.. etc
#
# depends on:
# unzip (infozip-version)
# zip   (infozip-version)
# tar   (gnu-version)
# rubygems
#
# the .gem is different from .zip and .tar.gz, because
# neither MANIFEST nor install.rb is necessary.
require 'fileutils'
require 'find'
require 'rubygems'

class ReleaseBuilder
	def initialize
		@release_name = nil
		@release_version = nil
		@populate_dir = nil
		@gemspec = nil
	end
	attr_accessor :release_name, :release_version, :populate_dir, :gemspec
	def self.mk_release(&block)
		rel = ReleaseBuilder.new
		block.call(rel)
		rel.execute
	end
	def assign_defaults
		@release_name ||= "noname-0.1"
		@release_version ||= "0.1"
		@populate_dir ||= lambda{}
		@gemspec ||= "TODO make a dummy gemspec"
	end
	def execute
		assign_defaults
		make_tarball
		make_gem
		# TODO: make_zip
		puts "DONE"
	end
	def make_dir(&block)
		dir_orig = FileUtils.pwd
		dir_rel = File.join(dir_orig, @release_name)
		if FileTest.directory?(dir_rel)
			FileUtils.rm_rf(dir_rel)
		end
		FileUtils.mkdir(dir_rel)
		@populate_dir.call(dir_rel)
		block.call(dir_rel)
		FileUtils.cd(dir_orig)
		FileUtils.rm_rf(dir_rel)
	end
	def filenames(dir)
		FileUtils.cd(dir)
		result = []
		Find.find(".") do |path|
			if FileTest.directory?(path)
				next
			else
				path.slice!(0, 2)  # remove prefix "./"
				result << path
			end
		end
		result.sort
	end
	def create_manifest_file(dir)
		result = filenames(dir) + ["MANIFEST"]
		manifest = result.sort.join("\n")+"\n" 
		File.open("MANIFEST", "w") { |f| f.write manifest }
	end
	def make_tarball
		toolsdir = FileUtils.pwd
		make_dir do |destdir|
			FileUtils.cp(File.join(toolsdir, "install.rb"), destdir)
			FileUtils.cp(File.join(toolsdir, "post-install.rb"), destdir)
			create_manifest_file(destdir)
			FileUtils.cd(toolsdir)
			puts "creating .tar.gz"
			system("tar czfv #{@release_name}.tar.gz #{@release_name}")
			puts "creating .zip"
			system("zip -r #{@release_name}.zip #{@release_name}")
		end
	end
	def rewrite_require_gem(dir)
		repl = "require 'rubygems'\nrequire_gem 'iterator'"
		filenames(dir).each do |filename|
			next unless /\.rb\z/.match(filename)
			data = nil
			File.open(filename, "r") { |f| data = f.read }
			data.gsub!(/^require\s+["']iterator["']$/, repl)
			File.open(filename, "w") { |f| f.write(data) }
		end
	end
	def make_gem
		toolsdir = FileUtils.pwd
		make_dir do |destdir|
			puts "creating .gem"
			FileUtils.cd(destdir)
			rewrite_require_gem(destdir)
			@gemspec.files = filenames(destdir)
			Gem::Builder.new(@gemspec).build
			FileUtils.move(Dir.glob("*.gem"), toolsdir)
		end
	end
end

def find_unnecessary_files(dir)
	FileUtils.cd(dir)
	files = Dir.entries(".")  # all files in the dir.. including dotfiles
	files.slice!(0, 2)  # remove "." and "..", so we don't kill em!
	files.map!{|file| dir+"/"+file}

	kill, keep = files.partition{|file|
		# files to be excluded
		file =~ /CVS$/
	}
	keep, kill2 = keep.partition{|file|
		# files to be included
		file =~ /\.rb$/
	}
	[keep, kill+kill2]
end

def copy_files(sourcedir, destdir)
	# copy source
	dir_lib = File.join(destdir, "lib")
	FileUtils.mkdir(dir_lib)
	FileUtils.cp(File.join(sourcedir, "source", "iterator.rb"), dir_lib)

	# copy test
	dir_test = File.join(destdir, "test")
	FileUtils.mkdir(dir_test)
	FileUtils.cp_r(File.join(sourcedir, "test", "."), dir_test)

	# copy samples
	dir_samples = File.join(destdir, "samples")
	FileUtils.mkdir(dir_samples)
	FileUtils.cp_r(File.join(sourcedir,"samples", "."), dir_samples)

	# remove unnessary files
	keep, kill   = find_unnecessary_files(dir_samples)
	keep2, kill2 = find_unnecessary_files(dir_test)
	keep += keep2
	kill += kill2
	kill.each { |file| FileUtils.rm_rf(file) } 

	# copy misc files
	FileUtils.cd(sourcedir)
	files = %w(README TODO LICENSE)
	FileUtils.cp(files, destdir)
end

if $0 == __FILE__
	require "../source/iterator"
	gemspec = Gem::Specification.new do |s|
		s.name = 'iterator'
		s.version = "#{Iterator::VERSION}"
		s.platform = Gem::Platform::RUBY
		s.summary = "bidirectional external iterators"
		s.description = <<TEXT
The overall design is stable. I don't expect any big changes.

   Collection,   iterates over an Array or similar containers.
   Reverse,      decorator which reverses the iterator.
   Range,        iterate in the range between two iterators.
   Concat,       concat multiple iterators into one.
   Continuation, turn #each_word/#each_byte into an iterator.
   ProxyLast,    remembers the last visited value.

Plus some StandardTemplateLibrary inspired methods that operate
on iterators.

   #copy
   #copy_n
   #copy_backward
   #fill
   #fill_n
   #transform
   #transform2
TEXT
		s.require_path = 'lib'
		s.autorequire = 'iterator'
		s.author = "Simon Strandgaard"
		s.email = "neoneye@adslhome.dk"
		s.rubyforge_project = "aeditor"
		s.homepage = "http://aeditor.rubyforge.org/iterator/"
		s.has_rdoc = true
	end            
	sourcedir = File.join(FileUtils.pwd, "..")
	ReleaseBuilder.mk_release do |rel|
		rel.release_name = "iterator-#{Iterator::VERSION}"
		rel.release_version =  Iterator::VERSION
		rel.populate_dir = lambda do |dirname|
			copy_files(sourcedir, dirname)
		end
		rel.gemspec = gemspec
	end
end
