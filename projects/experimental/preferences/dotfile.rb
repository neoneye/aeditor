# AEditor preferences for Simon Strandgaard
mode :global do
	tabsize 4
	#panel_format {|i| "#{i.y},#{i.xcell}-#{i.xchar}"}
end

mode :ruby => :global do
	tabsize 2
	#on_execute_project {|i| "ruby -v main.rb"}
	#on_execute_buffer {|i| "ruby -v #{i.filename}"} # record errors, so we can jump to them
	#on_execute_tests "ruby test_all.rb"
	#on_execute_builddoc {|i| "rdoc #{i.filename}"}
	#on_help_context { |place| "ri place" }
	#on_debug_step "gdb"
	#mode_selftest do
		# check that ruby is working
		# check rdoc is present
		# check ri is prsent
	#end
end
file_suffix %w(rb rbx) => :ruby

mode :rake => :ruby do
	# TODO: extract tasks, rules, files.. show choices
	#on_execute_buffer {|i| dialog('all', 'run', 'upload', 'validate')}
end
file_match %w(rakefile rakefile.rb) => :ruby

mode :c => :global do
end
file_suffix 'c' => :c

mode :cpp => :c
file_suffix %w(cpp cc) => :cpp

mode :xml => :global do
	#on_execute_buffer {|i| "xsltproc --validate #{i.filename}"} 
end
file_suffix %w(xml xhtml) => :xml

theme :morning do
end

theme :night do
end
