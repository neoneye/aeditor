require 'fileutils'
require 'find'

def is_release_file?(file)
	if file =~ /^[^.]\S+\.rb$/
		true
	else
		false
	end
end

def find_unnecessary_files(dir)
	FileUtils.cd(dir)
	files = Dir.entries(".")  # all files in the dir.. including dotfiles
	files.slice!(0, 2)  # remove "." and "..", so we don't kill em!
	files.map!{|file| File.expand_path(file)}
	keep, kill = files.partition { |file| 
		is_release_file?(File.basename(file)) 
	}
	[keep, kill]
end

def build_release(dir_root, release_name)
	dir_orig = FileUtils.pwd

	print "building directories ... "
	$stdout.flush
	dir_rel = dir_orig+"/"+release_name
	if FileTest.directory?(dir_rel)
		FileUtils.rm_rf(dir_rel)
	end
	FileUtils.mkdir(dir_rel)

	FileUtils.cd(dir_root)
	dir_root = FileUtils.pwd

	print "lib "
	$stdout.flush
	# create directories
	dir_test = dir_rel+"/test"
	FileUtils.mkdir(dir_test)
	dir_lib = dir_rel+"/lib"
	FileUtils.mkdir(dir_lib)
	dir_aeditor = dir_lib+"/aeditor"
	FileUtils.mkdir(dir_aeditor)
	dir_backend = dir_aeditor+"/backend"
	FileUtils.mkdir(dir_backend)
	dir_ncurses = dir_aeditor+"/ncurses"
	FileUtils.mkdir(dir_ncurses)

	# copy files into directories
	FileUtils.cp_r(dir_root+"/source/.", dir_backend)
	FileUtils.cp_r(dir_root+"/ncurses/.", dir_ncurses)
	FileUtils.cp_r(dir_root+"/test/.", dir_test)

	# remove unnessary files
	keep, kill   = find_unnecessary_files(dir_backend)
	keep2, kill2 = find_unnecessary_files(dir_ncurses)
	keep3, kill3 = find_unnecessary_files(dir_test)
	keep += keep2 + keep3
	kill += kill2 + kill3
	kill.each { |file| FileUtils.rm_rf(file) }

	print "bin "
	$stdout.flush
	dir_bin = dir_rel+"/bin"
	FileUtils.mkdir(dir_bin)
	FileUtils.cd(dir_orig)
	files = ["aeditor"]
	FileUtils.cp(files, dir_bin)

	print "root "
	$stdout.flush
	FileUtils.cd(dir_root)
	files = %w(CHANGES FEATURES INSTALL LICENSE README TODO USAGE)
	FileUtils.cp(files, dir_rel)
	FileUtils.cd(dir_orig)
	files = ["install.rb"]
	FileUtils.cp(files, dir_rel)
	puts "OK"

	print "creating manifest ... "
	$stdout.flush
	FileUtils.cd(dir_rel)
	result = ["MANIFEST"]
	Find.find(".") do |path|
		if FileTest.directory?(path)
			next
		else
			path.slice!(0, 2)  # remove prefix "./"
			result << path
		end
	end
	manifest = result.sort.join("\n")+"\n" 
	File.open("MANIFEST", "w") { |f| f.write manifest }
	puts "OK"

	print "creating tarball ... "
	$stdout.flush
	FileUtils.cd(dir_orig)
	compress = "tar czf #{release_name}.tar.gz #{release_name}"
	system(compress)
	puts "OK"

	print "cleaning up ... "
	$stdout.flush
	FileUtils.cd(dir_orig)
	#FileUtils.rm_rf(dir_rel)
	puts "OK"
end

if $0 == __FILE__
	require 'aeditor/backend/global'
	release_name = "aeditor-#{Global::VERSION}"
	build_release("..", release_name)
end
