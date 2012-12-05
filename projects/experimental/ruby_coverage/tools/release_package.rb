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
require 'rubygems/builder'

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

def copy_files(sourcedir, destdir)
	# copy source
	dir_lib = File.join(destdir, "lib")
	FileUtils.mkdir(dir_lib)
	FileUtils.cp(File.join(sourcedir, "source", "coverage.rb"), dir_lib)

	# copy misc files
	FileUtils.cd(sourcedir)
	files = %w(CHANGES README TODO)
	FileUtils.cp(files, destdir)
end

if $0 == __FILE__
	version = "0.3"
	gemspec = Gem::Specification.new do |s|
		s.name = 'coverage'
		s.version = "#{version}"
		s.platform = Gem::Platform::RUBY
		s.summary = "identifies inactive code"
		s.description = <<TEXT
output-format is XHTML1.0 strict

credit goes to
NAKAMURA Hiroshi, which made the original coverage in 47 lines of code!
Mauricio Julio Fernández Pradier, lots of improvements.
Robert Feldt, for suggestions.
Alex Pooley, for eliminating warnings.
TEXT
		s.require_path = 'lib'
		s.autorequire = 'coverage'
		s.author = "Simon Strandgaard"
		s.email = "neoneye@gmail.com"
		s.rubyforge_project = "aeditor"
		s.homepage = "http://aeditor.rubyforge.org"
	end            
	sourcedir = File.join(FileUtils.pwd, "..")
	ReleaseBuilder.mk_release do |rel|
		rel.release_name = "coverage-#{version}"
		rel.release_version = version
		rel.populate_dir = lambda do |dirname|
			copy_files(sourcedir, dirname)
		end
		rel.gemspec = gemspec
	end
end
