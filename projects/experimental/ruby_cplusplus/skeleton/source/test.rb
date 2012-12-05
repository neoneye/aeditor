# You can make changes to the "RubyView" class without recompiling!
# The Rubyembed Project
# $Id: test.rb,v 1.2 2003/09/20 14:09:14 neoneye Exp $
if $0 != "embed"
	print <<MSG
warning: you are executing an embedded ruby file!
this file is suppose to be run from "test" or "testswig"
MSG
end

print "test.rb: enter\n"

class ExampleRuby < Wrapper::ExampleBridgeRuby
	def initialize
		print "ExampleRuby.initialize: enter\n"
		super
		print "ExampleRuby.initialize: leave\n"
	end
	def execute
		print "ExampleRuby.execute: enter\n"
		callback
		print "ExampleRuby.execute: leave\n"
	end
end

def sweep
	print "sweep: enter\n"
	ObjectSpace.garbage_collect
	print "sweep: leave\n"
end

print "test.rb: leave\n"
