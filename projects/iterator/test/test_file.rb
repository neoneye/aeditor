require 'test/unit'
require 'iterator'

class TestFile < Test::Unit::TestCase
	def setup
		@data = "abcdefg"
		@filename = "____filedata"
		File.open(@filename, "w+") do |f|
			f.write(@data)
		end
		@file = File.open(@filename, "r")
		@i = Iterator::File.new(@file) 
		# @i is a data source which yields integers between 0..255 
	end
	def teardown
		@i.close
		raise "@file not closed" unless @file.closed?
	end
	def test_forward1
		result = []
		while @i.has_next?
			result << @i.current
			@i.next
		end
		assert_equal("abcdefg", result.map{|byte| byte.chr}.join)
	end
	def test_backward1
		@i.last
		result = []
		while @i.has_prev?
			result << @i.current_prev
			@i.prev
		end
		result.reverse!
		assert_equal("abcdefg", result.map{|byte| byte.chr}.join)
	end
	def test_backward2
		rev = @i.last.reverse
		result = []
		while rev.has_next?
			result << rev.current
			rev.next
		end
		result.reverse!
		assert_equal("abcdefg", result.map{|byte| byte.chr}.join)
	ensure
		rev.close
	end
	def test_clone1
		@i.next(2)
		assert_equal("c"[0], @i.current)
		i2 = @i.clone
		begin
			i2.next(2)
			assert_equal("e"[0], i2.current, 'dup has been fixed on:  ruby 1.9.0 (2004-05-26) [i386-freebsd5.1]')
			# check that clone were harmless
			assert_equal("c"[0], @i.current)
		ensure
			i2.close
		end
	end
	def test_clone2
		@i.next(2)
		assert_equal(2, @i.position)
		i2 = @i.clone
		begin
			i2.next(2)
			assert_equal(4, i2.position, 'dup has been fixed on:  ruby 1.9.0 (2004-05-26) [i386-freebsd5.1]')
			# check that clone were harmless
			assert_equal(2, @i.position)
		ensure
			i2.close
		end
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestFile)
end
