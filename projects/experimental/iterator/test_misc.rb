require 'test/unit'
require 'stream'

class TestMisc < Test::Unit::TestCase
	def mk_str16 
		(1..6).create_stream
	end
	def mk_str16x
		Stream::ImplicitStream.new{|s|
			x = 1
			s.at_end_proc = proc {x == 6}
			s.forward_proc = proc {x += 1}
			s.at_beginning_proc = proc {x == 0} # todo: why is'nt it {x == 1}
			s.backward_proc = proc {x -= 1}
		}
	end
	def setup
		@data = mk_str16.filtered{|x| x % 2 == 0}
		@data += mk_str16x.filtered{|x| x % 2 != 0}
	end
	def test_toa
		assert_equal([2, 4, 6, 1, 3, 5], @data.to_a)
	end
	def test_revtoa
		assert_equal([5, 3, 1, 6, 4, 2], @data.reverse.to_a)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestMisc)
end
